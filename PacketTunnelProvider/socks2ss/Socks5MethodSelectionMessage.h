//
//  Socks5MethodSelectionMessage.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5MethodSelectionMessage_h
#define Socks5MethodSelectionMessage_h

#include "net/Packer.h"
#include "Socks5Def.h"
#include <vector>

class Socks5MethodSelectionMessage: public WukongBase::Net::Packer {
public:
    Socks5MethodSelectionMessage() {}
    Socks5MethodSelectionMessage(const std::vector<Socks5Method>& methods);
    
    const std::vector<Socks5Method>& getMethods() const
    {
        return methods_;
    }
    
    virtual WukongBase::Net::Packet pack() const;
    virtual bool unpack(WukongBase::Net::Packet& packet);
private:
    std::vector<Socks5Method> methods_;
};

#endif /* Socks5MethodSelectionMessage_h */
