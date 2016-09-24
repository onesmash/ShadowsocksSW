//
//  Socks5MethodSelectionMessage.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks5MethodSelectionMessage.h"

#define kMinMessageLength 3

Socks5MethodSelectionMessage::Socks5MethodSelectionMessage(const std::vector<Socks5Method>& methods): methods_(methods)
{
    
}

WukongBase::Net::Packet Socks5MethodSelectionMessage::pack() const
{
    return WukongBase::Net::Packet();
}

bool Socks5MethodSelectionMessage::unpack(WukongBase::Net::Packet& packet)
{
    if(packet.size() < 3) {
        return false;
    }
    int8_t ver = packet.popInt8();
    int8_t methodNum = packet.popInt8();
    if(packet.size() < methodNum) {
        return false;
    }
    methods_ = std::vector<Socks5Method>((Socks5Method*)packet.data(), (Socks5Method*)packet.data() + methodNum);
    packet.pop(methodNum);
    return true;
}