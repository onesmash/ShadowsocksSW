//
//  PacketTunnelProvider.m
//  PacketTunnelProvider
//
//  Created by Xuhui on 16/9/13.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import "SWLogger.h"
#import "tun2socks.h"
#import "base/thread/Thread.h"
#import "base/message_loop/MessageLoop.h"
#import "net/IPAddress.h"
#import "TunnelInterface.h"
#import "MMWormhole.h"
#import "Socks2SS.h"
#import "ConfigManager.h"
#import "Common.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <MMWormhole.h>

@interface PacketTunnelProvider () {
    std::shared_ptr<WukongBase::Base::Thread> _socks2ShadowSocksServiceThread;
    std::shared_ptr<Socks2SS> _socks2ssService;
}

@property (nonatomic, strong) MMWormhole *wormhole;
@property (strong) void (^pendingStartCompletionHandler)(NSError *);
@property (strong) void (^pendingStopCompletionHandler)(void);

@end

@implementation PacketTunnelProvider

- (MMWormhole *)wormhole
{
    if(!_wormhole) {
        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kSharedGroupIdentifier
                                                         optionalDirectory:@"wormhole"];
    }
    return _wormhole;
}

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler
{
	// Add code here to start the process of connecting the tunnel.
    [Fabric with:@[[Crashlytics class]]];
    NSError *error = [TunnelInterface setupWithPacketTunnelFlow:self.packetFlow];
    if (error) {
        completionHandler(error);
        return;
    }
    if([self startSocks2ShadowSocksService:&error]) {
        [self setupTunnelNetworking:^(NSError *error) {
            if(!error) {
                NSError *error;
                if([self startTun2SocksService:&error] && [self setupWormhole:&error]) {
                    completionHandler(nil);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [TunnelInterface processPackets];
                    });
                } else {
                    completionHandler(error);
                }
                
            } else {
                completionHandler(error);
            }
        }];
    } else {
        completionHandler(error);
    }
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
	// Add code here to start the process of stopping the tunnel.
    [self stopTun2SocksService];
    [self stopSocks2ShadowSocksService];
	completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler
{
	// Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler
{
	// Add code here to get ready to sleep.
	completionHandler();
}

- (void)wake
{
	// Add code here to wake up.
}

- (BOOL)restartSocks2ShadowSocksService:(NSError **)error
{
    ShadowSocksConfig *config;
    if([ConfigManager sharedManager].usefreeShadowSocks) {
        int32_t index = arc4random_uniform((int32_t)[ConfigManager sharedManager].freeShadowSocksConfigs.count);
        config = [[ConfigManager sharedManager].freeShadowSocksConfigs objectAtIndex:(NSInteger)index];
    } else {
        config = [[ConfigManager sharedManager].shadowSocksConfigs objectAtIndex:[ConfigManager sharedManager].selectedShadowSocksIndex];
    }
    if(!config) {
        *error = [NSError errorWithDomain:kPacketTunnelProviderErrorDomain code:kPacketTunnelProviderErrorSocks2ssServiceStartFailed userInfo:nil];
        return NO;
    }
    NSString *hostname = config.ssServerAddress;
    const std::vector<WukongBase::Net::IPAddress>& addresses = WukongBase::Net::IPAddress::resolve(hostname.UTF8String);
    int32_t index = arc4random_uniform((int32_t)addresses.size());
    WukongBase::Net::IPAddress address = addresses[index];
    address.setPort(config.ssServerPort.integerValue);
    _socks2ssService->start(address, config.encryptionMethod.UTF8String, config.password.UTF8String);
    *error = nil;
    return YES;
}

- (BOOL)startSocks2ShadowSocksService:(NSError **)error
{
    ShadowSocksConfig *config;
    if([ConfigManager sharedManager].usefreeShadowSocks) {
        int32_t index = arc4random_uniform((int32_t)[ConfigManager sharedManager].freeShadowSocksConfigs.count);
        config = [[ConfigManager sharedManager].freeShadowSocksConfigs objectAtIndex:(NSInteger)index];
    } else {
        config = [[ConfigManager sharedManager].shadowSocksConfigs objectAtIndex:[ConfigManager sharedManager].selectedShadowSocksIndex];
    }
    if(!config) {
        *error = [NSError errorWithDomain:kPacketTunnelProviderErrorDomain code:kPacketTunnelProviderErrorSocks2ssServiceStartFailed userInfo:nil];
        return NO;
    }
    NSString *hostname = config.ssServerAddress;
    const std::vector<WukongBase::Net::IPAddress>& addresses = WukongBase::Net::IPAddress::resolve(hostname.UTF8String);
    int32_t index = arc4random_uniform((int32_t)addresses.size());
    WukongBase::Net::IPAddress address = addresses[index];
    address.setPort(config.ssServerPort.integerValue);
    _socks2ShadowSocksServiceThread = std::shared_ptr<WukongBase::Base::Thread>(new WukongBase::Base::Thread("socks2ss"));
    _socks2ShadowSocksServiceThread->start();
    _socks2ssService = std::shared_ptr<Socks2SS>(new Socks2SS(_socks2ShadowSocksServiceThread->messageLoop(), 2080));
    _socks2ssService->start(address, config.encryptionMethod.UTF8String, config.password.UTF8String);
    *error = nil;
    return YES;
}

- (void)stopSocks2ShadowSocksService
{
    _socks2ssService->stop();
}

- (BOOL)startTun2SocksService:(NSError **)error
{
    [TunnelInterface startTun2Socks:2080];
    *error = nil;
    return YES;
}

- (void)stopTun2SocksService
{
    [TunnelInterface stop];
}

- (void)setupTunnelNetworking:(void(^)(NSError *))completionHandler
{
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
    NSArray *dnsServers = @[@"8.8.8.8"];
    NSMutableArray *excludedRoutes = [NSMutableArray array];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"192.168.0.0" subnetMask:@"255.255.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"10.0.0.0" subnetMask:@"255.0.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"172.16.0.0" subnetMask:@"255.240.0.0"]];
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    ipv4Settings.excludedRoutes = excludedRoutes;
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"192.0.2.2"];
    settings.IPv4Settings = ipv4Settings;
    settings.MTU = @(TunnelMTU);
    NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];
    dnsSettings.matchDomains = @[@""];
    settings.DNSSettings = dnsSettings;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        if(completionHandler) {
            completionHandler(error);
        }
    }];
}

- (BOOL)setupWormhole:(NSError **)error
{
    __weak typeof(self) wself = self;
    [self.wormhole listenForMessageWithIdentifier:kWormholeSelectedConfigChangedNotification listener:^(id message) {
        SWLOG_INFO("Hello");
        NSError *error;
        [wself restartSocks2ShadowSocksService:&error];
    }];
    *error = nil;
    return YES;
}

@end
