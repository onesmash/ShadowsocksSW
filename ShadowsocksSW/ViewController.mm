//
//  ViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/7/27.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ViewController.h"
#import "SWLogger.h"
#import "ConfigManager.h"
#import "HeaderView.h"
#import "SectionHeaderView.h"
#import "TransparentNavigationBar.h"
#import "AddConfigViewController.h"
#import <IonIcons.h>
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource> {
    
}
@property (strong, nonatomic) IBOutlet UIButton *startBtn;
@property (strong, nonatomic) IBOutlet UIButton *stopBtn;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [self setupView];
    [_startBtn addTarget:self action:@selector(onStartBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_stopBtn addTarget:self action:@selector(onStopBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavigationBar
{
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [addBtn addTarget:self action:@selector(onAddConfigBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [addBtn setImage:[IonIcons imageWithIcon:ion_plus_round size:25 color:[UIColor greenColor]] forState:UIControlStateNormal];
    [addBtn sizeToFit];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addBtn];
}

- (void)setupView
{
    self.view.backgroundColor = [UIColor blackColor];
    HeaderView *headerView = [[HeaderView alloc] init];
    self.tableView.tableHeaderView = headerView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[SectionHeaderView class] forHeaderFooterViewReuseIdentifier:[SectionHeaderView reuseIdentifier]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ShadowSocksConfigCell"];
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
    AddConfigViewController *vc = [[AddConfigViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navi = [[UINavigationController alloc] initWithNavigationBarClass:[TransparentNavigationBar class] toolbarClass:nil];
    [navi pushViewController:vc animated:NO];
    [self presentViewController:navi animated:YES completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 55;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[SectionHeaderView reuseIdentifier]];
    headerView.text = @"选择配置";
    return headerView;
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if(section == 0) {
        return [ConfigManager sharedManager].shadowSocksConfigs.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        return [self cellForShadwoSocksConfigAtIndex:indexPath.row];
    }
    return nil;
}

- (UITableViewCell *)cellForShadwoSocksConfigAtIndex:(NSInteger)index
{
    ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[index];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ShadowSocksConfigCell"];
    cell.textLabel.text = config.configName.length ? config.configName : config.ssServerAddress;
    cell.textLabel.textColor = [UIColor greenColor];
    if(index == [ConfigManager sharedManager].selectedShadowSocksIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}
@end
