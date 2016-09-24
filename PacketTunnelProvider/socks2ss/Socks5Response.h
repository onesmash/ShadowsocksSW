//
//  Socks5Response.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5Response_h
#define Socks5Response_h

#include "net/Packer.h"
#include "net/IPAddress.h"
#include "Socks5Def.h"

class Socks5Response: public WukongBase::Net::Packer {
public:
    Socks5Response(Socks5ResponseStatus status, const WukongBase::Net::IPAddress& bindAddress);
    
    Socks5ResponseStatus getStatus() const
    {
        return status_;
    }
    
    virtual WukongBase::Net::Packet pack() const;
    virtual bool unpack(WukongBase::Net::Packet& packet);
private:
    Socks5ResponseStatus status_;
    Socks5AddressType addressType_;
    WukongBase::Net::IPAddress bindAddress_;
};

#endif /* Socks5Response_h */
