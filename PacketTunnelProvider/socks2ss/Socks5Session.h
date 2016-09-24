//
//  Socks5Session.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5Session_h
#define Socks5Session_h

#include "net/Packet.h"
#include <memory>
#include <functional>
#include <thread>

namespace WukongBase {
    
namespace Net {
    
class TCPSession;
    
}
}

class Socks5Request;
class Socks5Response;
class Socks5MethodSelectionMessage;
class Socks5MethodSelectionResponse;

class Socks5Session {
public:
    typedef std::function<void(const Socks5MethodSelectionMessage& request)> NegotiateCallback;
    typedef std::function<void(const std::shared_ptr<Socks5Request>& request)> RequestCallback;
    typedef std::function<void(std::shared_ptr<WukongBase::Net::Packet>&)> ReadCompleteCallback;
    typedef std::function<void(const WukongBase::Net::Packet& packet, bool)> WriteCompleteCallback;
    typedef std::function<void()> CloseCallback;
    Socks5Session(const std::shared_ptr<WukongBase::Net::TCPSession>& tcpSession);
    ~Socks5Session();
    
    void sendMethodSelectionResponse(const Socks5MethodSelectionResponse& response);
    void sendRequestResponse(const Socks5Response& response);
    void sendPacket(const WukongBase::Net::Packet& packet);
    void sendPacket(WukongBase::Net::Packet&& packet);
    
    void close();
    
    bool isClosed();
    
    void setNegotiateCallback(const NegotiateCallback& cb)
    {
        negotiateCallback_ = cb;
    }
    
    void setRequestCallback(const RequestCallback& cb)
    {
        requestCallback_ = cb;
    }
    
    void setReadCompleteCallback(const ReadCompleteCallback& cb)
    {
        readCompleteCallback_ = cb;
    }
    
    void setWriteCompleteCallback(const WriteCompleteCallback& cb)
    {
        writeCompleteCallback_ = cb;
    }
    
    void setCloseCallback(const CloseCallback& cb)
    {
        closeCallback_ = cb;
    }
private:
    enum Status {
        kInited,
        kNegotiating,
        kNegotiated,
        kRequesting,
        kRequested,
        kDiscontected
    };
    
    std::mutex lock_;
    Status status_;
    WukongBase::Net::Packet buffer_;
    NegotiateCallback negotiateCallback_;
    RequestCallback requestCallback_;
    ReadCompleteCallback readCompleteCallback_;
    WriteCompleteCallback writeCompleteCallback_;
    CloseCallback closeCallback_;
    std::shared_ptr<WukongBase::Net::TCPSession> tcpSession_;
};

#endif /* Socks5Session_h */
