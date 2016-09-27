//
//  ShadowSocksConfig.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ShadowSocksConfig.h"

#define kShadowSocksConfigServerAddressKey  @"kShadowSocksConfigServerAddressKey"
#define kShadowSocksConfigServerPortKey     @"kShadowSocksConfigServerPortKey"
#define kShadowSocksConfigPasswordKey       @"kShadowSocksConfigPasswordKey"
#define kShadowSocksConfigEncryptionMethod  @"kShadowSocksConfigEncryptionMethod"

@interface ShadowSocksConfig () <NSCoding>

@end

@implementation ShadowSocksConfig

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self) {
        self.ssServerAddress = [aDecoder decodeObjectForKey:kShadowSocksConfigServerAddressKey];
        self.ssServerPort = [aDecoder decodeObjectForKey:kShadowSocksConfigServerPortKey];
        self.password = [aDecoder decodeObjectForKey:kShadowSocksConfigPasswordKey];
        self.encryptionMethod = [aDecoder decodeObjectForKey:kShadowSocksConfigEncryptionMethod];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.ssServerAddress forKey:kShadowSocksConfigServerAddressKey];
    [aCoder encodeObject:self.ssServerPort forKey:kShadowSocksConfigServerPortKey];
    [aCoder encodeObject:self.password forKey:kShadowSocksConfigPasswordKey];
    [aCoder encodeObject:self.encryptionMethod forKey:kShadowSocksConfigEncryptionMethod];
}

@end
