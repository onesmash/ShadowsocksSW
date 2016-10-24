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
#define kShadowSocksConfigTimestampKey  @"kShadowSocksConfigTimestampKey"
#define kShadowSocksConfigConfigNameKey  @"kShadowSocksConfigConfigNameKey"
#define kShadowSocksConfigIsFreeKey  @"kShadowSocksConfigIsFreeKey"

@interface ShadowSocksConfig ()

@end

@implementation ShadowSocksConfig

- (instancetype)init
{
    self = [super init];
    if(self) {
        _isFree = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if(self) {
        self.ssServerAddress = [aDecoder decodeObjectForKey:kShadowSocksConfigServerAddressKey];
        self.ssServerPort = [aDecoder decodeObjectForKey:kShadowSocksConfigServerPortKey];
        self.password = [aDecoder decodeObjectForKey:kShadowSocksConfigPasswordKey];
        self.encryptionMethod = [aDecoder decodeObjectForKey:kShadowSocksConfigEncryptionMethodKey];
        self.timestamp = [aDecoder decodeIntegerForKey:kShadowSocksConfigTimestampKey];
        self.configName = [aDecoder decodeObjectForKey:kShadowSocksConfigConfigNameKey];
        self.isFree = [aDecoder decodeBoolForKey:kShadowSocksConfigIsFreeKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.ssServerAddress forKey:kShadowSocksConfigServerAddressKey];
    [aCoder encodeObject:self.ssServerPort forKey:kShadowSocksConfigServerPortKey];
    [aCoder encodeObject:self.password forKey:kShadowSocksConfigPasswordKey];
    [aCoder encodeObject:self.encryptionMethod forKey:kShadowSocksConfigEncryptionMethodKey];
    [aCoder encodeInteger:self.timestamp forKey:kShadowSocksConfigTimestampKey];
    [aCoder encodeObject:self.configName forKey:kShadowSocksConfigConfigNameKey];
    [aCoder encodeBool:self.isFree forKey:kShadowSocksConfigIsFreeKey];
}

@end
