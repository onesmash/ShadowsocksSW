 //
//  Socks5Request.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks5Request.h"
#include "SWLogger.h"

#define kIPv4Length 4
#define kIPv6Length 16
#define kSocks5IPv4RequestLength (1 + 1 + 1 + 1 + kIPv4Length + 2)
#define kSocks5IPv6RequestLength (1 + 1 + 1 + 1 + kIPv6Length + 2)
#define kSocks5DomainRequestLength (1 + 1 + 1 + 1 + 1 + 2)
#define kSocks5RequestMinLength kSocks5DomainRequestLength

Socks5Request::Socks5Request(Socks5CMD cmd, const WukongBase::Net::IPAddress& address)
:   valid_(true),
    cmd_(cmd),
    addressType_(address.isIPv6() ? kSocks5AddressIPv6 : kSocks5AddressIPv4),
    address_(address)
{
    
}

Socks5Request::Socks5Request(Socks5CMD cmd, const std::string& host, uint16_t port)
:   valid_(true),
    cmd_(cmd),
    addressType_(kSocks5AddressHostName),
    hostName_(host),
    port_(port)
{
    
}

WukongBase::Net::Packet Socks5Request::pack() const
{
    WukongBase::Net::Packet packet;
    if(valid_) {
        packet.appendInt8(5); // VER 5
        packet.appendInt8(cmd_); // CMD CONNECT
        packet.appendInt8(0); // RSV
        packet.appendInt8(addressType_); // ATYPE
        switch (addressType_) {
            case kSocks5AddressIPv4: {
                const sockaddr_in* address = (const sockaddr_in*)address_.sockAddress();
                packet.append((void*)&address->sin_addr, sizeof(address->sin_addr));
                packet.append((void*)&address->sin_port, sizeof(address->sin_port));
            } break;
            case kSocks5AddressIPv6: {
                const sockaddr_in6* address = (const sockaddr_in6*)address_.sockAddress();
                packet.append((void*)&address->sin6_addr, sizeof(address->sin6_addr));
                packet.append((void*)&address->sin6_port, sizeof(address->sin6_port));
            } break;
            case kSocks5AddressHostName: {
                packet.appendInt8(hostName_.size());
                packet.append((void*)hostName_.c_str(), hostName_.size());
                packet.appendInt16(port_);
            } break;
            default:
                break;
        }
    } else {
        packet.appendInt8(0);
    }
    
    
    return packet;
}

bool Socks5Request::unpack(WukongBase::Net::Packet& packet)
{
    if(packet.size() <= kSocks5RequestMinLength) {
        return false;
    }
    int8_t ver = packet.popInt8();
    cmd_ = (Socks5CMD)packet.popInt8();
    int8_t rsv = packet.popInt8();
    addressType_ = (Socks5AddressType)packet.popInt8();
    switch (addressType_) {
        case kSocks5AddressIPv4: {
//            if(packet.size() < kSocks5IPv4RequestLength) {
//                return false;
//            }
            sockaddr_in address = {0};
            address.sin_family = AF_INET;
            packet.pop(&address.sin_addr, sizeof(address.sin_addr));
            packet.pop(&address.sin_port, sizeof(address.sin_port));
            address_ = WukongBase::Net::IPAddress((const sockaddr*)&address);
        } break;
        case kSocks5AddressIPv6: {
//            if(packet.size() < kSocks5IPv6RequestLength) {
//                return false;
//            }
            sockaddr_in6 address = {0};
            address.sin6_family = AF_INET6;
            packet.pop(&address.sin6_addr, sizeof(address.sin6_addr));
            packet.pop(&address.sin6_port, sizeof(address.sin6_port));
            address_ = WukongBase::Net::IPAddress((const sockaddr*)&address);
        } break;
        case kSocks5AddressHostName: {
//            if(packet.size() < kSocks5DomainRequestLength) {
//                return false;
//            }
            int len = packet.popInt8();
            if(packet.size() < len + 2) {
                return false;
            }
            char buf[255] = {'\0'};
            packet.pop(buf, len);
            hostName_ = std::string(buf, len);
            port_ = packet.popInt16();
        } break;
        default:
            break;
    }
    valid_ = true;
    return true;
}