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
@property (strong, nonatomic) IBOutlet UIButton *startBtn;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;

@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [_startBtn addTarget:self action:@selector(onStartBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_stopBtn addTarget:self action:@selector(onStopBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAddConfigBtnClicked:)];
}

- (void)onVPNContectNotification:(NSNotification *)note
{
    
}

- (void)onStartBtnClicked:(id)sender
{
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
}

- (void)onStopBtnClicked:(id)sender
{
    [_tunelProviderManager.connection stopVPNTunnel];
}
                                              
- (void)onAddConfigBtnClicked:(id)sender
{
    
}

@end
