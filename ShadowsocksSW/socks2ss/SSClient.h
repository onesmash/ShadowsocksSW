//
//  SSClient.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef SSClient_h
#define SSClient_h

#include "base/thread/ThreadPool.h"
#include "net/IPAddress.h"
#include "Crypto.h"
#include <string>
#include <functional>
#include <unordered_map>
#include <thread>

namespace WukongBase {
    
namespace Base {
class IOBuffer;
}
    
namespace Net {

class Packet;
    
}
}

class SSTCPRelayRequest;
class SSTCPRelaySession;

class SSClient {
public:
    typedef std::function<void(const std::shared_ptr<SSTCPRelaySession>&, const std::shared_ptr<SSTCPRelayRequest>&, bool)> RequestCallback;
    SSClient(const WukongBase::Net::IPAddress& ssRemote, CipherType type, const std::string& password, int threadNum = 4);
    SSClient(const std::string& ssRemoteHost, uint16_t port, CipherType type, const std::string& password, int threadNum = 4);
    
    void sendTCPRelayRequest(const std::shared_ptr<SSTCPRelayRequest>& request);
    void sendUDPData(const std::shared_ptr<WukongBase::Net::Packet>& packet);
    
    void setRequestCallback(const RequestCallback& cb)
    {
        requestCallback_ = cb;
    }
    
private:
    std::mutex lock_;
    WukongBase::Base::ThreadPool threadPool_;
    RequestCallback requestCallback_;
    WukongBase::Net::IPAddress remoteAddress_;
    std::string hostName_;
    uint16_t port_;
    bool needDnsResolve_;
    CipherType cipherType_;
    std::string password_;
    std::unordered_map<std::shared_ptr<SSTCPRelayRequest>, std::shared_ptr<SSTCPRelaySession>> sessionMap_;
};

#endif /* SSClient_h */
