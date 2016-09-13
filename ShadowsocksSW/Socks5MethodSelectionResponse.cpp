//
//  Socks5MethodSelectionResponse.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Socks5MethodSelectionResponse.h"

WukongBase::Net::Packet Socks5MethodSelectionResponse::pack() const
{
    WukongBase::Net::Packet packet;
    packet.appendInt8(5);
    packet.appendInt8(method_);
    return packet;
}

bool Socks5MethodSelectionResponse::unpack(WukongBase::Net::Packet& packet)
{
    return false;
}