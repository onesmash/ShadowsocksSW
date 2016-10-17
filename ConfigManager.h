//
//  ConfigManager.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShadowSocksConfig.h"

#define kSharedGroupIdentifier @"group.io.github.onesmash.shadowsockssw"
#define kWormholeSelectedConfigChangedNotification @"kWormholeSelectedConfigChangedNotification"

@interface ConfigManager : NSObject

@property (nonatomic, assign) BOOL usefreeShadowSocks;
@property (nonatomic, readonly) NSArray<ShadowSocksConfig *> *freeShadowSocksConfigs;
@property (nonatomic, readonly) NSArray<ShadowSocksConfig *> *shadowSocksConfigs;
@property (nonatomic, assign) NSInteger selectedShadowSocksIndex;
@property (nonatomic, copy) NSString *mainAppLogFile;
@property (nonatomic, copy) NSString *tunnelProviderLogFile;

+ (instancetype)sharedManager;
- (BOOL)addConfig:(ShadowSocksConfig *)config;
- (BOOL)deleteConfig:(NSInteger)index;
- (BOOL)replaceConfig:(NSInteger)index withConfig:(ShadowSocksConfig *)config;

- (void)asyncFetchFreeConfig:(void(^)(NSError *error))complition;

@end
