//
//  SSTCPRelayRequest.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "SSTCPRelayRequest.h"
#include "SWLogger.h"
#include <fmt/format.h>


SSTCPRelayRequest::SSTCPRelayRequest(const WukongBase::Net::IPAddress& address)
:   valid_(true),
    addressType_(address.isIPv6() ? kAddressTypeIPv6 : kAddressTypeIPv4),
    address_(address)
{
    
}

SSTCPRelayRequest::SSTCPRelayRequest(const std::string& host, uint16_t port)
:   valid_(true),
    addressType_(kAddressTypeHostName),
    hostName_(host),
    port_(port)
{
    
}


WukongBase::Net::Packet SSTCPRelayRequest::pack() const
{
    WukongBase::Net::Packet packet;
    if(valid_) {
        packet.appendInt8(addressType_);
        switch (addressType_) {
            case kAddressTypeIPv4: {
                const sockaddr_in* address = (const sockaddr_in*)address_.sockAddress();
                packet.append((void*)&address->sin_addr, sizeof(address->sin_addr));
                packet.append((void*)&address->sin_port, sizeof(address->sin_port));
            } break;
            case kAddressTypeIPv6: {
                const sockaddr_in6* address = (const sockaddr_in6*)address_.sockAddress();
                packet.append((void*)&address->sin6_addr, sizeof(address->sin6_addr));
                packet.append((void*)&address->sin6_port, sizeof(address->sin6_port));
            } break;
            case kAddressTypeHostName: {
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

bool SSTCPRelayRequest::unpack(WukongBase::Net::Packet& packet)
{
    addressType_ = (AddressType)packet.popInt8();
    switch (addressType_) {
        case kAddressTypeIPv4: {
            sockaddr_in address = {0};
            address.sin_family = AF_INET;
            packet.pop(&address.sin_addr, sizeof(address.sin_addr));
            packet.pop(&address.sin_port, sizeof(address.sin_port));
            address_ = WukongBase::Net::IPAddress((const sockaddr*)&address);
        } break;
        case kAddressTypeIPv6: {
            sockaddr_in6 address = {0};
            address.sin6_family = AF_INET6;
            packet.pop(&address.sin6_addr, sizeof(address.sin6_addr));
            packet.pop(&address.sin6_port, sizeof(address.sin6_port));
            address_ = WukongBase::Net::IPAddress((const sockaddr*)&address);
        } break;
        case kAddressTypeHostName: {
            int len = packet.popInt8();
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

std::string SSTCPRelayRequest::stringify() const
{
    return fmt::format("");
}
