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
#import "TunnelInterface.h"
#import "MMWormhole.h"
#import "Socks2SS.h"
#import "dns.h"

@interface PacketTunnelProvider () {
    std::shared_ptr<WukongBase::Base::Thread> _socks2ShadowSocksServiceThread;
    std::shared_ptr<Socks2SS> _socks2ssService;
}

@property (strong) void (^pendingStartCompletionHandler)(NSError *);
@property (strong) void (^pendingStopCompletionHandler)(void);

@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler
{
	// Add code here to start the process of connecting the tunnel.
    NSLog(@"tunnel provider start");
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

- (BOOL)startSocks2ShadowSocksService:(NSError **)error
{
    _socks2ShadowSocksServiceThread = std::shared_ptr<WukongBase::Base::Thread>(new WukongBase::Base::Thread("socks2ss"));
    _socks2ShadowSocksServiceThread->start();
    _socks2ssService = std::shared_ptr<Socks2SS>(new Socks2SS(_socks2ShadowSocksServiceThread->messageLoop(), 2080));
    _socks2ssService->start(WukongBase::Net::IPAddress("54.249.0.5", 8989), "aes-256-cfb", "howtoget!@");
    *error = nil;
    return YES;
}

- (void)stopSocks2ShadowSocksService
{
    //_socks2ShadowSocksServiceThread->stop();
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
    NSArray *dnsServers = [DNSConfig getSystemDnsServers];
    NSMutableArray *excludedRoutes = [NSMutableArray array];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"192.168.0.0" subnetMask:@"255.255.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"10.0.0.0" subnetMask:@"255.0.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"172.16.0.0" subnetMask:@"255.240.0.0"]];
    //[excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"127.0.0.1" subnetMask:@"255.255.255.255"]];
    //[excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"54.249.0.5" subnetMask:@"255.255.255.255"]];
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    ipv4Settings.excludedRoutes = excludedRoutes;
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"54.249.0.5"];
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
    *error = nil;
    return YES;
}

@end
