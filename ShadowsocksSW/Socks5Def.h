//
//  Socks5Def.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Socks5Def_h
#define Socks5Def_h

enum Socks5AddressType {
    kSocks5AddressIPv4 = 0x01,
    kSocks5AddressIPv6 = 0x04,
    kSocks5AddressHostName = 0x03,
};

enum Socks5ResponseStatus {
    kSocks5ResponseStatusSuccess  = 0x00,
    kSocks5ResponseStatusFailed   = 0x01,
    kSocks5ResponseCMDNotSupport  = 0x07,
};

enum Socks5CMD
{
    kSocks5CMDConnect = 0x01
};

enum Socks5Method {
    kSocks5MethodNoAuth = 0x00,
    kSocks5MethodNotAccept = 0xff
};

#endif /* Socks5Def_h */
