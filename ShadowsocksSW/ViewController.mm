//
//  ViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/7/27.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ViewController.h"
#import "SWLogger.h"
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController () {
    
}

@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVPNContectNotification:) name:NEVPNStatusDidChangeNotification object:nil];
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> *managers, NSError *error) {
        if(managers.count > 0) {
            _tunelProviderManager = managers.firstObject;
        } else {
            _tunelProviderManager = [[NETunnelProviderManager alloc] init];
            _tunelProviderManager.localizedDescription = @"ShadowsocksSW";
            _tunelProviderManager.protocolConfiguration = [NETunnelProviderProtocol new];
        }
        _tunelProviderManager.onDemandEnabled = NO;
        _tunelProviderManager.protocolConfiguration.serverAddress = @"ShadowsocksSW";
        _tunelProviderManager.enabled = YES;
        [_tunelProviderManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
            if(_tunelProviderManager.connection.status == NEVPNStatusDisconnected || _tunelProviderManager.connection.status == NEVPNStatusInvalid) {
                NSError *error;
                if([_tunelProviderManager.connection startVPNTunnelAndReturnError:&error]) {
                    SWLOG_DEBUG("tunnel provider start success");
                } else {
                    
                }
            }
        }];
        
    }];
    
    // Do any additional setup after loading the view, typically from a nib.
//    client.setRequestCallback([](const SSTCPRelaySession& session, const std::shared_ptr<SSTCPRelayRequest>&, bool success) {
//        WukongBase::Net::URLRequest request("http://onesmash.github.io");
//        request.setHTTPMethod("GET");
//        session.sendData(request.pack());
//    });
//    client.setWriteCompleteCallback([](const SSTCPRelaySession&, const WukongBase::Net::Packet& packet, bool success) {
//        
//    });
//    client.setMessageCallback([](const SSTCPRelaySession&, const std::shared_ptr<WukongBase::Base::IOBuffer>& buffer) {
//        printf(buffer->data());
//    });
//    client.setCloseCallback([](const SSTCPRelaySession&){
//        
//    });
//    std::shared_ptr<SSTCPRelayRequest> request(new SSTCPRelayRequest("onesmash.github.io", 80));
//    client.sendTCPRelayRequest(request);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onVPNContectNotification:(NSNotification *)note
{
    
}

@end
