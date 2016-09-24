//
//  SSTCPRelaySession.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef SSTCPRelaySession_h
#define SSTCPRelaySession_h

#include <memory>
#include <functional>
#include <thread>

namespace WukongBase {
namespace Base {
class IOBuffer;
}
    
namespace Net {
class TCPClient;
class TCPSession;
class Packet;
class IPAddress;
}
}

class SSTCPRelayRequest;
class Crypto;

class SSTCPRelaySession {
public:
    typedef std::function<void(const std::shared_ptr<SSTCPRelayRequest>&, bool)> RequestCallback;
    typedef std::function<void(std::shared_ptr<WukongBase::Net::Packet>&)> ReadCompleteCallback;
    typedef std::function<void(const WukongBase::Net::Packet& packet, bool)> WriteCompleteCallback;
    typedef std::function<void()> CloseCallback;
    SSTCPRelaySession(const std::shared_ptr<WukongBase::Net::TCPClient>& tcpClient, const std::shared_ptr<Crypto>& crypto);
    ~SSTCPRelaySession();
    
    void sendRequest(const std::shared_ptr<SSTCPRelayRequest>& request);
    void sendPacket(const WukongBase::Net::Packet& packet);
    void sendPacket(WukongBase::Net::Packet&& packet);
    
    void close();
    
    bool isClosed();
    
    const WukongBase::Net::IPAddress& getLocalAddress() const;
    const WukongBase::Net::IPAddress& getPeerAddress() const;
    
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
    
    enum State { kDisconnected, kConnecting, kConnected, kDisconnecting, kAuthorizing, kAuthorized};
    
    State state_;
    std::mutex lock_;
    
    std::shared_ptr<Crypto> crypto_;
    RequestCallback requestCallback_;
    ReadCompleteCallback readCompleteCallback_;
    WriteCompleteCallback writeCompleteCallback_;
    CloseCallback closeCallback_;
    bool receivedPacketHasIVPrepend_;
    std::shared_ptr<WukongBase::Net::TCPClient> tcpClient_;
    std::shared_ptr<WukongBase::Net::TCPSession> tcpSession_;
};

#endif /* SSTCPRelaySession_h */
