//
//  Socks2SS.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/4.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks2SS.h"
#include "Socks5Session.h"
#include "Crypto.h"
#include "SSTCPRelayRequest.h"
#include "SSTCPRelaySession.h"
#include "Socks5Request.h"
#include "SSClient.h"
#include "Socks5MethodSelectionMessage.h"
#include "net/TCPSession.h"
#include "base/message_loop/MessageLoop.h"
#include "Socks5MethodSelectionResponse.h"
#include "SWLogger.h"
#include <iostream>
#include <cassert>
using namespace std;

Socks2SS::Socks2SS(WukongBase::Base::MessageLoop* messageLoop, uint16_t port)
:   lock_(), messageLoop_(messageLoop), socksServer_(messageLoop, WukongBase::Net::IPAddress("127.0.0.1", port)), nextChannelID_(0), isRestart_(false)
{
    socksServer_.setConnectCallback([this](const std::shared_ptr<WukongBase::Net::TCPSession>& session) {
        std::shared_ptr<Socks5Session> socksSession(new Socks5Session(session));
        setupSocksSession(socksSession);
    });
    socksServer_.setStopCallback([this]() {
        std::lock_guard<std::mutex> guard(lock_);
        if(isRestart_) {
            isRestart_ = false;
            socksServer_.start();
        } else {
            channelMap_.clear();
            paddingRequestMap_.clear();
        }
    });
}

Socks2SS::~Socks2SS()
{
}

void Socks2SS::start(const WukongBase::Net::IPAddress& ssRemote, const std::string& encryptionMethod, const std::string& password)
{
    ssClient_ = std::shared_ptr<SSClient>(new SSClient(ssRemote, Crypto::getCipherTypeByName(encryptionMethod), password));
    setupSSClient(ssClient_);
    if(socksServer_.isStarted()) {
        isRestart_ = true;
        socksServer_.stop();
    } else {
        socksServer_.start();
    }
}

void Socks2SS::start(const std::string& ssRemoteHost, uint16_t port, const std::string& encryptionMethod, const std::string& password)
{
    ssClient_ = std::shared_ptr<SSClient>(new SSClient(ssRemoteHost, port, Crypto::getCipherTypeByName(encryptionMethod), password));
    setupSSClient(ssClient_);
    if(socksServer_.isStarted()) {
        isRestart_ = true;
        socksServer_.stop();
    } else {
        socksServer_.start();
    }
}

void Socks2SS::setupSSClient(const std::shared_ptr<SSClient>& client)
{
    client->setRequestCallback([this](const std::shared_ptr<SSTCPRelaySession>& session, const std::shared_ptr<SSTCPRelayRequest>& request, bool success) {
        std::lock_guard<std::mutex> guard(lock_);
        uint64_t channelID;
        auto iter = paddingRequestMap_.find(request.get());
        if(iter != paddingRequestMap_.end()) {
            channelID = iter->second;
            session->setWriteCompleteCallback([](const WukongBase::Net::Packet& packet, bool success) {
                
            });
            session->setReadCompleteCallback([this, channelID](std::shared_ptr<WukongBase::Net::Packet>& packet) {
                std::lock_guard<std::mutex> guard(lock_);
                const Socks2SSChannel* channel = getChannelByID(channelID);
                if(channel) {
                    channel->socks5Session->sendPacket(std::move(*packet));
                }
            });
            session->setCloseCallback([this, channelID]() {
                std::lock_guard<std::mutex> guard(lock_);
                closeChannel(channelID);
            });
            Socks2SSChannel* channel = getChannelByID(channelID);
            if(channel) {
                channel->ssSession = session;
                channel->status = kEstablished;
                SWLOG_DEBUG("socks 2 ss channel {} estabilished", channelID);
                if(success) {
                    const WukongBase::Net::IPAddress& bindAddress = session->getLocalAddress();
                    Socks5Response response(kSocks5ResponseStatusSuccess, bindAddress);
                    channel->socks5Session->sendRequestResponse(response);
                } else {
                    Socks5Response response(kSocks5ResponseStatusFailed, WukongBase::Net::IPAddress());
                    channel->socks5Session->sendRequestResponse(response);
                    messageLoop_->postDelayTask([this, channelID]() {
                        std::lock_guard<std::mutex> guard(lock_);
                        closeChannel(channelID);
                    }, timeDeltaFromSeconds(10));
                }
                SWLOG_DEBUG("socks5 connect {}", success);
            } else {
                session->close();
            }
            requestCallback_(success);
        } else {
            assert(false);
        }
        paddingRequestMap_.erase(request.get());
    });
}

void Socks2SS::setupSocksSession(const std::shared_ptr<Socks5Session>& socksSession)
{
    uint64_t channelID;
    {
        std::lock_guard<std::mutex> guard(lock_);
        channelID = createChanel(socksSession, nullptr);
    }
    socksSession->setNegotiateCallback([this, channelID](const Socks5MethodSelectionMessage& message) {
        SWLOG_DEBUG("socks5 Negotiate start");
        std::lock_guard<std::mutex> guard(lock_);
        const Socks2SSChannel* channel = getChannelByID(channelID);
        if(channel) {
            const Socks5MethodSelectionResponse& response = genMethodSelectionResponse(message);
            channel->socks5Session->sendMethodSelectionResponse(response);
            if(response.getMethod() != kSocks5MethodNoAuth) {
                messageLoop_->postDelayTask([this, channelID]() {
                    std::lock_guard<std::mutex> guard(lock_);
                    closeChannel(channelID);
                }, timeDeltaFromSeconds(10));
            }
        }
    });
    socksSession->setRequestCallback([this, channelID](const std::shared_ptr<Socks5Request>& request) {
        std::lock_guard<std::mutex> guard(lock_);
        Socks2SSChannel* channel = getChannelByID(channelID);
        if(request->getCMD() != kSocks5CMDConnect) {
            if(channel) {
                const Socks5Response& response = genResponse(kSocks5ResponseCMDNotSupport, WukongBase::Net::IPAddress());
                channel->socks5Session->sendRequestResponse(response);
                messageLoop_->postDelayTask([this, channelID]() {
                    std::lock_guard<std::mutex> guard(lock_);
                    closeChannel(channelID);
                }, timeDeltaFromSeconds(10));
            }
        } else {
            std::shared_ptr<SSTCPRelayRequest> ssRequest;
            if(request->getAddressType() == kSocks5AddressHostName) {
                SWLOG_DEBUG("ss channel {} request: {} : {}", channelID, request->getHostName(), request->getPort());
                ssRequest = std::shared_ptr<SSTCPRelayRequest>(new SSTCPRelayRequest(request->getHostName(), request->getPort()));
            } else {
                SWLOG_DEBUG("ss channel {} request: {} : {}", channelID, request->getIPAddress().stringify(), request->getIPAddress().getPort());
                ssRequest = std::shared_ptr<SSTCPRelayRequest>(new SSTCPRelayRequest(request->getIPAddress()));
            }
            if(channel) {
                channel->status = kWaittingSSesion;
                paddingRequestMap_.insert({ssRequest.get(), channelID});
                ssClient_->sendTCPRelayRequest(ssRequest);
            }
        }
    });
    socksSession->setWriteCompleteCallback([](const WukongBase::Net::Packet& packet, bool) {
    });
    socksSession->setReadCompleteCallback([this, channelID](std::shared_ptr<WukongBase::Net::Packet>& packet) {
        std::lock_guard<std::mutex> guard(lock_);
        const Socks2SSChannel* channel = getChannelByID(channelID);
        if(channel) {
            channel->ssSession->sendPacket(std::move(*packet));
        }
    });
    socksSession->setCloseCallback([this, channelID]() {
        std::lock_guard<std::mutex> guard(lock_);
        closeChannel(channelID);
    });
}

void Socks2SS::stop()
{
    socksServer_.stop();
}

Socks5MethodSelectionResponse Socks2SS::genMethodSelectionResponse(const Socks5MethodSelectionMessage& message)
{
    const auto methods = message.getMethods();
    for (auto iter = methods.begin(); iter != methods.end(); ++iter) {
        if(*iter == kSocks5MethodNoAuth) {
            return Socks5MethodSelectionResponse(kSocks5MethodNoAuth);
        }
    }
    return Socks5MethodSelectionResponse(kSocks5MethodNotAccept);
}

Socks5Response Socks2SS::genResponse(Socks5ResponseStatus status, const WukongBase::Net::IPAddress& bindAddress)
{
    return Socks5Response(status, bindAddress);
}

uint64_t Socks2SS::createChanel(const std::shared_ptr<Socks5Session>& socks5Session, const std::shared_ptr<SSTCPRelaySession>& ssSession)
{
    channelMap_.insert({nextChannelID_, {socks5Session, ssSession, nextChannelID_, kInited}});
    return nextChannelID_++;
}

void Socks2SS::closeChannel(uint64_t channelID)
{
    Socks2SSChannel* channel = getChannelByID(channelID);
    if(channel) {
        switch (channel->status) {
            case kInited: {
                if(!channel->socks5Session->isClosed()) {
                    channel->socks5Session->close();
                    channel->status = kClosing;
                } else {
                    channel->status = kClosed;
                }
            } break;
            case kWaittingSSesion: {
                if(!channel->socks5Session->isClosed()) {
                    channel->socks5Session->close();
                    channel->status = kClosing;
                } else {
                    channel->status = kClosed;
                }
                
            } break;
            case kEstablished: {
                if(!channel->socks5Session->isClosed()) {
                    channel->socks5Session->close();
                    channel->status = kClosing;
                }
                if(!channel->ssSession->isClosed()) {
                    channel->ssSession->close();
                    channel->status = kClosing;
                }
                if(channel->socks5Session->isClosed() && channel->ssSession->isClosed()) {
                    channel->status = kClosed;
                }
            } break;
            case kClosing: {
                if(channel->socks5Session->isClosed() && channel->ssSession->isClosed()) {
                    channel->status = kClosed;
                }
            } break;
            case kClosed: {
                SWLOG_DEBUG("socks 2 ss channel {} closed", channelID);
            } break;
            default:
                break;
        }
        if(channel->status == kClosed) {
            channelMap_.erase(channelID);
        }
    }
}

Socks2SSChannel* Socks2SS::getChannelByID(uint64_t ID)
{
    auto iter = channelMap_.find(ID);
    return iter != channelMap_.end() ? &(iter->second) : nullptr;
}
