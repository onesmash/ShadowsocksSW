//
//  Socks5MethodSelectionResponse.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5MethodSelectionResponse_h
#define Socks5MethodSelectionResponse_h

#include "net/Packer.h"
#include "Socks5Def.h"

class Socks5MethodSelectionResponse: public WukongBase::Net::Packer {
public:
    Socks5MethodSelectionResponse(Socks5Method method): method_(method) {}
    
    Socks5Method getMethod() const
    {
        return method_;
    }
    
    virtual WukongBase::Net::Packet pack() const;
    virtual bool unpack(WukongBase::Net::Packet& packet);
private:
    Socks5Method method_;
};

#endif /* Socks5MethodSelectionResponse_h */
