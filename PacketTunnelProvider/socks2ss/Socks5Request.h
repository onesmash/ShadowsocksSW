//
//  Socks5Request.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5Request_h
#define Socks5Request_h

#include "net/Packer.h"
#include "net/IPAddress.h"
#include "Socks5Def.h"

class Socks5Request: public WukongBase::Net::Packer {
public:
    Socks5Request(): valid_(false) {}
    Socks5Request(Socks5CMD cmd, const WukongBase::Net::IPAddress& address);
    Socks5Request(Socks5CMD cmd, const std::string& host, uint16_t port);
    
    Socks5CMD getCMD() const
    {
        return cmd_;
    }
    
    Socks5AddressType getAddressType() const
    {
        return addressType_;
    }
    
    WukongBase::Net::IPAddress getIPAddress() const
    {
        return address_;
    }
    
    const std::string& getHostName() const
    {
        return hostName_;
    }
    
    uint16_t getPort() const
    {
        return port_;
    }
    
    virtual WukongBase::Net::Packet pack() const;
    virtual bool unpack(WukongBase::Net::Packet& packet);
private:
    
    bool valid_;
    Socks5CMD cmd_;
    Socks5AddressType addressType_;
    WukongBase::Net::IPAddress address_;
    std::string hostName_;
    uint16_t port_;

};

#endif /* Socks5Request_h */
