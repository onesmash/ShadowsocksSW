//
//  Socks2SS.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/4.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef socks2ss_h
#define socks2ss_h

#include "net/IPAddress.h"
#include "net/TCPClient.h"
#include "net/TCPServer.h"
#include "Socks5Response.h"
#include "Socks5MethodSelectionResponse.h"
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <thread>

namespace WukongBase {
namespace Base {
class MessageLoop;
}
}

class Socks5Session;
class Socks5Request;
class Socks5MethodSelectionMessage;
class SSTCPRelaySession;
class SSTCPRelayRequest;
class SSClient;

enum ChannelStatus {
    kInited,
    kWaittingSSesion,
    kEstablished,
    kClosing,
    kClosed
};

struct Socks2SSChannel {
    
    std::shared_ptr<Socks5Session> socks5Session;
    std::shared_ptr<SSTCPRelaySession> ssSession;
    uint64_t channelID;
    ChannelStatus status;
};

class Socks2SS {
public:
    Socks2SS(WukongBase::Base::MessageLoop* messageLoop, uint16_t port);
    void start(const WukongBase::Net::IPAddress& ssRemote, const std::string& encryptionMethod, const std::string& password);
    void start(const std::string& ssRemoteHost, uint16_t port, const std::string& encryptionMethod, const std::string& password);
    void stop();
private:
    Socks5MethodSelectionResponse genMethodSelectionResponse(const Socks5MethodSelectionMessage& message);
    Socks5Response genResponse(Socks5ResponseStatus status, const WukongBase::Net::IPAddress& bindAddress);
    uint64_t createChanel(const std::shared_ptr<Socks5Session>& socks5Session, const std::shared_ptr<SSTCPRelaySession>& ssSession);
    void closeChannel(uint64_t channelID);
    Socks2SSChannel* getChannelByID(uint64_t ID);
    void setupSSClient(const std::shared_ptr<SSClient>&);
    void setupSocksSession(const std::shared_ptr<Socks5Session>&);
    
    std::mutex lock_;
    WukongBase::Base::MessageLoop* messageLoop_;
    WukongBase::Net::TCPServer socksServer_;
    std::shared_ptr<SSClient> ssClient_;
    std::unordered_map<uint64_t, Socks2SSChannel> channelMap_;
    std::unordered_map<SSTCPRelayRequest*, uint64_t> paddingRequestMap_;
    uint64_t nextChannelID_;
};

#endif /* Socks2SS_h */
