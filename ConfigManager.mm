//
//  ConfigManager.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/25.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ConfigManager.h"
#import "Common.h"
#import <AFNetworking.h>
#import <MMWormhole.h>

#define kConfigKey @"kConfigKey"
#define kSelectedFreeConfigIndexKey @"kSelectedFreeConfigIndexKey"
#define kSelectedConfigIndexKey @"kSelectedConfigIndexKey"
#define kFreeShadowsocksConifgEtagKey @"kFreeShadowsocksConifgEtagKey"
#define kFreeShadowsocksConifgTimestampKey @"kFreeShadowsocksConifgTimestampKey"
#define kFreeShadowsocksConifgKey @"kFreeShadowsocksConifgKey"
#define kNeedShowFreeShadowsocksConifgUpdateTipKey @"kNeedShowFreeShadowsocksConifgUpdateTipKey"
#define kUsefreeShadowSocksKey @"kUsefreeShadowSocksKey"
#define kCanActivePacketTunnelKey @"kCanActivePacketTunnelKey"
#define kFreeShadowsocksConifgURL @"https://raw.githubusercontent.com/onesmash/fss/master/fss.txt"

@interface ConfigManager () {
    NSMutableArray<ShadowSocksConfig *> *_shadowSocksConfigs;
    NSArray<ShadowSocksConfig *> *_freeShadowSocksConfigs;
}

@property (nonatomic, strong) NSURL *appGroupContainer;
@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@property (nonatomic, copy) NSString *fssEtag;
@property (nonatomic, assign) NSTimeInterval fssTimestamp;
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) MMWormhole *wormhole;
@property (nonatomic, strong) NSDictionary *admobPlist;
@property (nonatomic, strong) NSSet *encryptonMethods;
@end

@interface ShadowSocksConfigSerializer : AFHTTPResponseSerializer

+ (instancetype)serializer;

@end

@implementation ShadowSocksConfigSerializer

+ (instancetype)serializer
{
    static ShadowSocksConfigSerializer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ShadowSocksConfigSerializer alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    }
    return self;
}

#pragma mark - AFURLResponseSerialization

static BOOL AFErrorOrUnderlyingErrorHasCodeInDomain(NSError *error, NSInteger code, NSString *domain) {
    if ([error.domain isEqualToString:domain] && error.code == code) {
        return YES;
    } else if (error.userInfo[NSUnderlyingErrorKey]) {
        return AFErrorOrUnderlyingErrorHasCodeInDomain(error.userInfo[NSUnderlyingErrorKey], code, domain);
    }
    
    return NO;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || AFErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, AFURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }
    
    NSMutableArray<ShadowSocksConfig *> *configs = [NSMutableArray array];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *components = [text componentsSeparatedByString:@"\n"];
    [components enumerateObjectsUsingBlock:^(NSString *text, NSUInteger index, BOOL *stop) {
        if([text hasPrefix:@"#"]) {
            NSArray *components = [text componentsSeparatedByString:@" "];
            [ConfigManager sharedManager].fssTimestamp = [[components objectAtIndex:0] substringFromIndex:1].doubleValue;
        } else {
            NSArray *components = [text componentsSeparatedByString:@" "];
            if(components.count >= 4) {
                ShadowSocksConfig *config = [[ShadowSocksConfig alloc] init];
                config.isFree = YES;
                config.ssServerAddress = components[0];
                config.ssServerPort = components[1];
                config.password = components[2];
                config.encryptionMethod = components[3];
                if(components.count == 5) {
                    config.country = components[4];
                }
                [configs addObject:config];
            }
        }
    }];
    return configs;
    
}

@end

@implementation ConfigManager

@synthesize shadowSocksConfigs = _shadowSocksConfigs;
@synthesize freeShadowSocksConfigs = _freeShadowSocksConfigs;

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
        self.appGroupContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedGroupIdentifier].filePathURL;
        self.mainAppLogFile = [NSString stringWithUTF8String:[self.appGroupContainer URLByAppendingPathComponent:@"mainAppLog"].fileSystemRepresentation];
        self.tunnelProviderLogFile = [NSString stringWithUTF8String:[self.appGroupContainer URLByAppendingPathComponent:@"tunnelProviderLog"].fileSystemRepresentation];
        _sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedGroupIdentifier];
        _httpSessionManager = [AFHTTPSessionManager manager];
        _httpSessionManager.responseSerializer = [ShadowSocksConfigSerializer serializer];
        NSString *admobPlistPath = [[NSBundle mainBundle] pathForResource:@"Admob" ofType:@"plist"];
        _admobPlist = [NSDictionary dictionaryWithContentsOfFile:admobPlistPath];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_sharedDefaults synchronize];
}

- (NSSet *)encryptonMethods
{
    if(!_encryptonMethods) {
        _encryptonMethods = [NSSet setWithArray:@[@"rc4",
                                                  @"aes-128-cfb",
                                                  @"aes-192-cfb",
                                                  @"aes-256-cfb",
                                                  @"bf-cfb",
                                                  @"camellia-128-cfb",
                                                  @"camellia-192-cfb",
                                                  @"camellia-256-cfb",
                                                  @"cast5-cfb",
                                                  @"des-cfb",
                                                  @"idea-cfb",
                                                  @"rc2-cfb",
                                                  @"seed-cfb"]];
    }
    return _encryptonMethods;
}

- (NSString *)displayName
{
    return @"DarkNetSW";
}

- (NSString *)logFilePath
{
#if defined(TUNNEL_PROVIDER)
    return self.tunnelProviderLogFile;
#else
    return self.mainAppLogFile;
#endif
}

- (NSString *)version
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)build
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSString *)googleAppID
{
    return [_admobPlist objectForKey:@"GoogleAppID"];
}

- (NSString *)adUnitID
{
    return [_admobPlist objectForKey:@"AdUnitID"];
}

- (MMWormhole *)wormhole
{
    if(!_wormhole) {
        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kSharedGroupIdentifier
                                                         optionalDirectory:@"wormhole"];
    }
    return _wormhole;
}

- (NSArray<ShadowSocksConfig *> *)shadowSocksConfigs
{
    if(!_shadowSocksConfigs) {
        NSData *data = [_sharedDefaults objectForKey:kConfigKey];
        _shadowSocksConfigs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if(!_shadowSocksConfigs) {
            _shadowSocksConfigs = [NSMutableArray array];
        }
    }
    return _shadowSocksConfigs;
}

- (void)setShadowSocksConfigs:(NSArray<ShadowSocksConfig *> *)shadowSocksConfigs
{
    _shadowSocksConfigs = [NSMutableArray arrayWithArray:shadowSocksConfigs];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_shadowSocksConfigs];
    [_sharedDefaults setObject:data forKey:kConfigKey];
    [_sharedDefaults synchronize];
}

- (BOOL)addConfig:(ShadowSocksConfig *)config
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.shadowSocksConfigs];
    [array addObject:config];
    self.shadowSocksConfigs = array;
    return YES;
}

- (BOOL)deleteConfig:(NSInteger)index
{
    [_shadowSocksConfigs removeObjectAtIndex:index];
    self.shadowSocksConfigs = _shadowSocksConfigs;
    if(index < self.selectedShadowSocksIndex) {
        self.selectedShadowSocksIndex--;
    } else if(index == self.selectedShadowSocksIndex) {
        self.usefreeShadowSocks = YES;
        [self.wormhole passMessageObject:nil identifier:kWormholeSelectedConfigChangedNotification];
    }
    return YES;
}

- (BOOL)replaceConfig:(NSInteger)index withConfig:(ShadowSocksConfig *)config
{
    [_shadowSocksConfigs setObject:config atIndexedSubscript:index];
    self.shadowSocksConfigs = _shadowSocksConfigs;
    return YES;
}

- (NSInteger)selectedFreeShadowSocksIndex
{
    return [(NSNumber *)[_sharedDefaults objectForKey:kSelectedFreeConfigIndexKey] integerValue];
}

- (void)setSelectedFreeShadowSocksIndex:(NSInteger)selectedFreeShadowSocksIndex
{
    if(self.selectedFreeShadowSocksIndex != selectedFreeShadowSocksIndex) {
        [_sharedDefaults setObject:@(selectedFreeShadowSocksIndex) forKey:kSelectedFreeConfigIndexKey];
        [_sharedDefaults synchronize];
        //[self.wormhole passMessageObject:nil identifier:kWormholeSelectedConfigChangedNotification];
    }
}

- (NSInteger)selectedShadowSocksIndex
{
    return [(NSNumber *)[_sharedDefaults objectForKey:kSelectedConfigIndexKey] integerValue];
}

- (void)setSelectedShadowSocksIndex:(NSInteger)selectedShadowSocksIndex
{
    if(self.selectedShadowSocksIndex != selectedShadowSocksIndex) {
        [_sharedDefaults setObject:@(selectedShadowSocksIndex) forKey:kSelectedConfigIndexKey];
        [_sharedDefaults synchronize];
        //[self.wormhole passMessageObject:nil identifier:kWormholeSelectedConfigChangedNotification];
    }
}

- (NSArray<ShadowSocksConfig *> *)freeShadowSocksConfigs
{
    if(!_freeShadowSocksConfigs) {
        NSData *data = [_sharedDefaults objectForKey:kFreeShadowsocksConifgKey];
        _freeShadowSocksConfigs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if(!_freeShadowSocksConfigs) {
            _freeShadowSocksConfigs = [NSMutableArray array];
        }
    }
    return _freeShadowSocksConfigs;
}

- (void)setFreeShadowSocksConfigs:(NSArray<ShadowSocksConfig *> *)freeShadowSocksConfigs
{
    _freeShadowSocksConfigs = freeShadowSocksConfigs;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_freeShadowSocksConfigs];
    [_sharedDefaults setObject:data forKey:kFreeShadowsocksConifgKey];
    [_sharedDefaults synchronize];
    if(self.usefreeShadowSocks) {
        [self.wormhole passMessageObject:nil identifier:kWormholeSelectedConfigChangedNotification];
    }
}

- (NSString *)fssEtag
{
    return [_sharedDefaults objectForKey:kFreeShadowsocksConifgEtagKey] ? : @"";
}

- (void)setFssEtag:(NSString *)fssEtag
{
    [_sharedDefaults setObject:fssEtag forKey:kFreeShadowsocksConifgEtagKey];
    [_sharedDefaults synchronize];
}

- (NSTimeInterval)fssTimestamp
{
    return [_sharedDefaults doubleForKey:kFreeShadowsocksConifgTimestampKey];
}

- (void)setFssTimestamp:(NSTimeInterval)fssTimestamp
{
    [_sharedDefaults setDouble:fssTimestamp forKey:kFreeShadowsocksConifgTimestampKey];
    [_sharedDefaults synchronize];
}

- (BOOL)usefreeShadowSocks
{
    return [[_sharedDefaults objectForKey:kUsefreeShadowSocksKey] boolValue];
}

- (void)setUsefreeShadowSocks:(BOOL)usefreeShadowSocks
{
    if(self.usefreeShadowSocks != usefreeShadowSocks) {
        [_sharedDefaults setObject:@(usefreeShadowSocks) forKey:kUsefreeShadowSocksKey];
        [_sharedDefaults synchronize];
        //[self.wormhole passMessageObject:nil identifier:kWormholeSelectedConfigChangedNotification];
    }
}

- (BOOL)canActivePacketTunnel
{
    return [[_sharedDefaults objectForKey:kCanActivePacketTunnelKey] boolValue];
}

- (void)setCanActivePacketTunnel:(BOOL)canActivePacketTunnel
{
    if(self.canActivePacketTunnel != canActivePacketTunnel) {
        [_sharedDefaults setObject:@(canActivePacketTunnel) forKey:kCanActivePacketTunnelKey];
        [_sharedDefaults synchronize];
    }
}

- (void)setNeedShowFreeShadowSocksConfigsUpdateTip:(BOOL)needShowFreeShadowSocksConfigsUpdateTip
{
    [_sharedDefaults setObject:@(needShowFreeShadowSocksConfigsUpdateTip) forKey:kNeedShowFreeShadowsocksConifgUpdateTipKey];
    [_sharedDefaults synchronize];
}

- (BOOL)needShowFreeShadowSocksConfigsUpdateTip
{
    return [[_sharedDefaults objectForKey:kNeedShowFreeShadowsocksConifgUpdateTipKey] boolValue];
}

- (void)asyncFetchFreeConfig:(BOOL)force withCompletion:(void(^)(NSError *error))complitionHandler
{
    [_httpSessionManager GET:kFreeShadowsocksConifgURL parameters:nil progress:nil success:^(NSURLSessionDataTask *task, NSArray<ShadowSocksConfig *> *configs) {
        self.freeShadowSocksConfigs = configs;
        self.needShowFreeShadowSocksConfigsUpdateTip = NO;
        if(complitionHandler) complitionHandler(nil);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if(complitionHandler) complitionHandler(error);
    }];
}

- (BOOL)checkEncryptionMethodSupport:(NSString *)method
{
    return [self.encryptonMethods containsObject:method];
}

- (NSString *)packetTunnelLog
{
    NSString *path = [NSString stringWithFormat:@"%@.txt", self.tunnelProviderLogFile];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        NSString *log = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        return log;
    }
    return @"";
}

#pragma mark - Notification

 - (void)onUIApplicationWillResignActiveNotification:(NSNotification *)note
 {
     [_sharedDefaults synchronize];
 }
@end
