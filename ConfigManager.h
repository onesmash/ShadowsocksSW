//
//  ConfigManager.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShadowSocksConfig.h"

@interface ConfigManager : NSObject

@property (nonatomic, readonly, copy) NSString *appGroupIdentifier;
@property (nonatomic, readonly) NSArray<ShadowSocksConfig *> *shadowSocksConfigs;
@property (nonatomic, assign) NSInteger selectedShadowSocksIndex;
@property (nonatomic, copy) NSString *mainAppLogFile;
@property (nonatomic, copy) NSString *tunnelProviderLogFile;

+ (instancetype)sharedManager;
- (BOOL)deleteConfig:(NSInteger)index;
- (BOOL)replaceConfig:(NSInteger)index withConfig:(ShadowSocksConfig *)config;

@end
