//
//  DNS.m
//  ShadowsocksSW
//
//  Created by Xuhui on 23/10/2016.
//  Copyright © 2016 Xuhui. All rights reserved.
//

#import "DNS.h"
#import "net/IPAddress.h"
#import <sys/types.h>
#import <netinet/in.h>
#import <arpa/nameser.h>
#import <resolv.h>
#import <arpa/inet.h>

@implementation DNS

+ (NSArray *)getSystemDnsServers
{
    res_state res = (res_state)malloc(sizeof(struct __res_state));
    res_ninit(res);
    NSMutableArray *servers = [NSMutableArray array];
    for (int i = 0; i < res->nscount; i++) {
        NSString *address = [NSString stringWithUTF8String:WukongBase::Net::IPAddress::stringify((const sockaddr*)&(res->nsaddr_list[i])).c_str()];
        if (address.length) {
            [servers addObject:address];
        }
    }
    res_ndestroy(res);
    free(res);
    return servers;
}

@end
