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
#define kShadowSocksConfigEncryptionMethodKey  @"kShadowSocksConfigEncryptionMethodKey"
#define kShadowSocksConfigConfigNameKey  @"kShadowSocksConfigConfigNameKey"

@interface ShadowSocksConfig () <NSCoding>

@end

@implementation ShadowSocksConfig

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if(self) {
        self.ssServerAddress = [aDecoder decodeObjectForKey:kShadowSocksConfigServerAddressKey];
        self.ssServerPort = [aDecoder decodeObjectForKey:kShadowSocksConfigServerPortKey];
        self.password = [aDecoder decodeObjectForKey:kShadowSocksConfigPasswordKey];
        self.encryptionMethod = [aDecoder decodeObjectForKey:kShadowSocksConfigEncryptionMethodKey];
        self.configName = [aDecoder decodeObjectForKey:kShadowSocksConfigConfigNameKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.ssServerAddress forKey:kShadowSocksConfigServerAddressKey];
    [aCoder encodeObject:self.ssServerPort forKey:kShadowSocksConfigServerPortKey];
    [aCoder encodeObject:self.password forKey:kShadowSocksConfigPasswordKey];
    [aCoder encodeObject:self.encryptionMethod forKey:kShadowSocksConfigEncryptionMethodKey];
    [aCoder encodeObject:self.configName forKey:kShadowSocksConfigConfigNameKey];
}

@end
