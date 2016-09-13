//
//  Socks5Response.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks5Response.h"

Socks5Response::Socks5Response(Socks5ResponseStatus status, const WukongBase::Net::IPAddress& bindAddress)
:   status_(status),
    addressType_(bindAddress.isIPv6() ? kSocks5AddressIPv6 : kSocks5AddressIPv4),
    bindAddress_(bindAddress)
{
    
}

WukongBase::Net::Packet Socks5Response::pack() const
{
    WukongBase::Net::Packet packet;
    packet.appendInt8(5);           // VER 5
    packet.appendInt8(status_);
    packet.appendInt8(0);           // RSV
    packet.appendInt8(addressType_); // ATYPE
    switch (addressType_) {
        case kSocks5AddressIPv4: {
            const sockaddr_in* address = (const sockaddr_in*)bindAddress_.sockAddress();
            packet.append((void*)&address->sin_addr, sizeof(address->sin_addr));
            packet.append((void*)&address->sin_port, sizeof(address->sin_port));
        } break;
        case kSocks5AddressIPv6: {
            const sockaddr_in6* address = (const sockaddr_in6*)bindAddress_.sockAddress();
            packet.append((void*)&address->sin6_addr, sizeof(address->sin6_addr));
            packet.append((void*)&address->sin6_port, sizeof(address->sin6_port));
        } break;
        default:
            break;
    }
    
    return packet;
}

bool Socks5Response::unpack(WukongBase::Net::Packet& packet)
{
    return false;
}