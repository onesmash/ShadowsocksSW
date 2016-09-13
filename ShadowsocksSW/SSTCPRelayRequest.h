//
//  SSTCPRelayRequest.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef SSTCPRelayRequest_h
#define SSTCPRelayRequest_h

#include "net/Packer.h"
#include "net/IPAddress.h"
#include <string>

namespace WukongBase {
namespace Net {

class Packet;

}
}

class SSTCPRelayRequest: public WukongBase::Net::Packer {
public:
    SSTCPRelayRequest(): valid_(false) {}
    SSTCPRelayRequest(const WukongBase::Net::IPAddress& address);
    SSTCPRelayRequest(const std::string& host, uint16_t port);
    
    virtual WukongBase::Net::Packet pack() const;
    virtual bool unpack(WukongBase::Net::Packet& packet);
private:
    enum AddressType {
        kAddressTypeIPv4 = 1,
        kAddressTypeIPv6 = 4,
        kAddressTypeHostName = 3,
    };
    
    bool valid_;
    AddressType addressType_;
    WukongBase::Net::IPAddress address_;
    std::string hostName_;
    uint16_t port_;
};

#endif /* SSTCPRelayRequest_h */
