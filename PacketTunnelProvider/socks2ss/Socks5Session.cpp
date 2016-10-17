//
//  Socks5Session.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks5Session.h"
#include "net/TCPSession.h"
#include "Socks5MethodSelectionMessage.h"
#include "Socks5Request.h"
#include "Socks5Response.h"
#include "Socks5MethodSelectionResponse.h"
#include <cassert>

Socks5Session::Socks5Session(const std::shared_ptr<WukongBase::Net::TCPSession>& tcpSession)
:   tcpSession_(tcpSession),
    status_(kInited)
{
    tcpSession_->startRead();
    tcpSession_->setReadCompleteCallback([this](std::shared_ptr<WukongBase::Net::Packet>& packet) {
        lock_.lock();
        if(status_ == kRequested) {
            lock_.unlock();
            readCompleteCallback_(packet);
        } else if (status_ == kInited || status_ == kNegotiating) {
            status_ = kNegotiating;
            buffer_.append((void*)packet->data(), packet->size());
            WukongBase::Net::Packet p(buffer_);
            Socks5MethodSelectionMessage selectionMessage;
            if(selectionMessage.unpack(p)) {
                lock_.unlock();
                negotiateCallback_(selectionMessage);
                lock_.lock();
                buffer_.clear();
                status_ = kNegotiated;
            }
            lock_.unlock();
        } else if (status_ == kNegotiated || status_ == kRequesting) {
            status_ = kRequesting;
            buffer_.append((void*)packet->data(), packet->size());
            WukongBase::Net::Packet p(buffer_);
            std::shared_ptr<Socks5Request> request(new Socks5Request());
            if(request->unpack(p)) {
                lock_.unlock();
                requestCallback_(request);
                lock_.lock();
                buffer_.clear();
                status_ = kRequested;
            }
            lock_.unlock();
        } else {
            lock_.unlock();
        }
    });
    tcpSession_->setWriteCompleteCallback([this](const WukongBase::Net::Packet& packet, bool success) {
        lock_.lock();
        if(status_ == kRequested) {
            lock_.unlock();
            writeCompleteCallback_(packet, success);
        } else {
            lock_.unlock();
        }
    });
    tcpSession_->setCloseCallback([this](bool) {
        {
            std::lock_guard<std::mutex> guard(lock_);
            status_ = kDiscontected;
        }
        closeCallback_();
    });
}

Socks5Session::~Socks5Session()
{
    //assert(tcpSession_->isClosed());
    tcpSession_ = nullptr;
}

void Socks5Session::sendMethodSelectionResponse(const Socks5MethodSelectionResponse& response)
{
    tcpSession_->send(response.pack());
}

void Socks5Session::sendRequestResponse(const Socks5Response& response)
{
    tcpSession_->send(response.pack());
}

void Socks5Session::sendPacket(const WukongBase::Net::Packet& packet)
{
    tcpSession_->send(packet);
}

void Socks5Session::sendPacket(WukongBase::Net::Packet&& packet)
{
    tcpSession_->send(std::move(packet));
}

void Socks5Session::close()
{
    tcpSession_->close();
}

bool Socks5Session::isClosed()
{
    return tcpSession_->isClosed();
}
