//
//  SSClient.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "SSClient.h"
#include "net/TCPClient.h"
#include "base/message_loop/MessageLoop.h"
#include "SSTCPRelayRequest.h"
#include "SSTCPRelaySession.h"

SSClient::SSClient(const WukongBase::Net::IPAddress& ssRemote, CipherType type, const std::string& password, int threadNum)
:   threadPool_(threadNum),
    remoteAddress_(ssRemote),
    needDnsResolve_(false),
    cipherType_(type),
    password_(password)
{
    threadPool_.start();
}

SSClient::SSClient(const std::string& ssRemoteHost, uint16_t port, CipherType type, const std::string& password, int threadNum)
:   threadPool_(threadNum),
    hostName_(ssRemoteHost),
    port_(port),
    needDnsResolve_(true),
    cipherType_(type),
    password_(password)
{
    threadPool_.start();
}

void SSClient::sendTCPRelayRequest(const std::shared_ptr<SSTCPRelayRequest>& request)
{
    const std::shared_ptr<WukongBase::Base::Thread>& thread = threadPool_.getThread();
    std::shared_ptr<WukongBase::Net::TCPClient> client;
    if(needDnsResolve_) {
        client.reset(new WukongBase::Net::TCPClient(thread->messageLoop(), hostName_, port_));
    } else {
        client.reset(new WukongBase::Net::TCPClient(thread->messageLoop(), remoteAddress_));
    }
    std::shared_ptr<Crypto> crypto(new Crypto(cipherType_, password_));
    std::shared_ptr<SSTCPRelaySession> session(new SSTCPRelaySession(client, crypto));
    std::lock_guard<std::mutex> guard(lock_);
    sessionMap_.insert({request, session});
    session->setRequestCallback([this](const std::shared_ptr<SSTCPRelayRequest>& request, bool success) {
        lock_.lock();
        auto iter = sessionMap_.find(request);
        if(iter != sessionMap_.end()) {
            lock_.unlock();
            requestCallback_(iter->second, request, success);
            lock_.lock();
            if(success) {
                sessionMap_.erase(iter);
            }
        }
        lock_.unlock();
    });
    session->setCloseCallback([this, request]() {
        std::lock_guard<std::mutex> guard(lock_);
        auto iter = sessionMap_.find(request);
        if(iter != sessionMap_.end()) {
            sessionMap_.erase(iter);
        }
    });
    session->sendRequest(request);
}

void SSClient::sendUDPData(const std::shared_ptr<WukongBase::Net::Packet>& packet)
{
    
}

void SSClient::stop()
{
    threadPool_.stop();
}
