//
//  ConfigManager.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ConfigManager.h"
#import <LevelDB.h>

static NSString *const sharedGroupIdentifier = @"group.io.github.shadowsocksSW";

#define kConfigKey @"kConfigKey"
#define kSelectedConfigIndexKey @"kSelectedConfigIndexKey"

@interface ConfigManager () {
    NSMutableArray<ShadowSocksConfig *> *_shadowSocksConfigs;
}

@property (nonatomic, strong) NSURL *appGroupContainer;
@property (nonatomic, strong) LevelDB *ldb;

@end

@implementation ConfigManager

@synthesize shadowSocksConfigs = _shadowSocksConfigs;

+ (instancetype)sharedManager
{
    static ConfigManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ConfigManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.appGroupContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:sharedGroupIdentifier].filePathURL;
        self.mainAppLogFile = [NSString stringWithUTF8String:[self.appGroupContainer URLByAppendingPathComponent:@"mainAppLog"].fileSystemRepresentation];
        self.tunnelProviderLogFile = [NSString stringWithUTF8String:[self.appGroupContainer URLByAppendingPathComponent:@"tunnelProviderLog"].fileSystemRepresentation];
        LevelDBOptions options = [LevelDB makeOptions];
        options.createIfMissing = true;
        options.errorIfExists   = false;
        options.paranoidCheck   = false;
        options.compression     = false;
        options.filterPolicy    = 0;
        options.cacheSize       = 0;
        _ldb = [[LevelDB alloc] initWithPath:[NSString stringWithUTF8String:self.appGroupContainer.fileSystemRepresentation] name:@"config.ldb" andOptions:options];
        _shadowSocksConfigs = [_ldb objectForKey:kConfigKey] ? : [NSMutableArray array];
        _selectedShadowSocksIndex = [(NSNumber *)[_ldb objectForKey:kSelectedConfigIndexKey] integerValue];
    }
    return self;
}

- (NSString *)appGroupIdentifier
{
    return sharedGroupIdentifier;
}

- (BOOL)addConfig:(ShadowSocksConfig *)config
{
    [_shadowSocksConfigs addObject:config];
    _ldb.safe = YES;
    [_ldb setObject:_shadowSocksConfigs forKey:kConfigKey];
    _ldb.safe = NO;
    return YES;
}

- (BOOL)deleteConfig:(NSInteger)index
{
    if(index == _selectedShadowSocksIndex) return NO;
    _ldb.safe = YES;
    [_shadowSocksConfigs removeObjectAtIndex:index];
    [_ldb setObject:_shadowSocksConfigs forKey:kConfigKey];
    if(index < _selectedShadowSocksIndex) {
        _selectedShadowSocksIndex--;
        [_ldb setObject:@(_selectedShadowSocksIndex) forKey:kSelectedConfigIndexKey];
    }
    _ldb.safe = NO;
    return YES;
}

- (BOOL)replaceConfig:(NSInteger)index withConfig:(ShadowSocksConfig *)config
{
    [_shadowSocksConfigs setObject:config atIndexedSubscript:index];
    _ldb.safe = YES;
    [_ldb setObject:_shadowSocksConfigs forKey:kConfigKey];
    _ldb.safe = NO;
    return YES;
}

- (void)setSelectedShadowSocksIndex:(NSInteger)selectedShadowSocksIndex
{
    _selectedShadowSocksIndex = selectedShadowSocksIndex;
    _ldb.safe = YES;
    [_ldb setObject:@(_selectedShadowSocksIndex) forKey:kSelectedConfigIndexKey];
    _ldb.safe = NO;
}

@end
