//
//  ConfigManager.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ConfigManager.h"

static NSString *const sharedGroupIdentifier = @"group.io.github.shadowsocksSW";

@interface ConfigManager () {
    NSArray<ShadowSocksConfig *> *_shadowSocksConfigs;
}

@property (nonatomic, strong) NSURL *appGroupContainer;
@property (nonatomic, copy) NSString *configFile;

@end

@implementation ConfigManager

@synthesize shadowSocksConfigs = _shadowSocksConfigs;

+ (instancetype)sharedManager
{
    static ConfigManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ConfigManager alloc] init];
        manager.appGroupContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:sharedGroupIdentifier].filePathURL;
        manager.configFile = [NSString stringWithUTF8String:[manager.appGroupContainer URLByAppendingPathComponent:@"config"].fileSystemRepresentation];
        manager.mainAppLogFile = [NSString stringWithUTF8String:[manager.appGroupContainer URLByAppendingPathComponent:@"mainAppLog"].fileSystemRepresentation];
        manager.tunnelProviderLogFile = [NSString stringWithUTF8String:[manager.appGroupContainer URLByAppendingPathComponent:@"tunnelProviderLog"].fileSystemRepresentation];
    });
    return manager;
}

- (NSString *)appGroupIdentifier
{
    return sharedGroupIdentifier;
}

@end
