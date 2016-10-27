//
//  ViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/7/27.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "ViewController.h"
#import "Common.h"
#import "SWLogger.h"
#import "ConfigManager.h"
#import "HeaderView.h"
#import "SectionHeaderView.h"
#import "TransparentNavigationBar.h"
#import "AddConfigViewController.h"
#import "SWUITextView.h"
#import "CommonTableViewCell.h"
#import "TransparentNavigationBar.h"
#import "ConfigCell.h"
#import <UIView+Toast.h>
#import <IonIcons.h>
#import <Firebase.h>
#import <MBProgressHUD.h>
#import <Reachability.h>
#import <VTAcknowledgementViewController.h>
#import <VTAcknowledgementsViewController.h>
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, AddConfigViewControllerDelegate, HeaderViewDelegate, GADInterstitialDelegate> {
    
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) HeaderView *headerView;
@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (nonatomic, strong) GADInterstitial *interstitial;
@property (nonatomic, assign) BOOL connectAfterAdDismiss;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupAdmob];
    [self setupNavigationBar];
    [self setupView];
    [self setupVPN];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    reachability.reachableBlock = ^(Reachability *reachability) {
        
    };
    [reachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIApplicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    _headerView = [[HeaderView alloc] init];
    _headerView.delegate = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    self.tableView.tableHeaderView = _headerView;
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[SectionHeaderView class] forHeaderFooterViewReuseIdentifier:[SectionHeaderView reuseIdentifier]];
    [self.tableView registerClass:[CommonTableViewCell class] forCellReuseIdentifier:@"ShadowSocksConfigCell"];
    [self.tableView registerClass:[CommonTableViewCell class] forCellReuseIdentifier:@"Acknowlagement"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ConfigCell" bundle:nil] forCellReuseIdentifier:@"Version"];
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    _hud.removeFromSuperViewOnHide = YES;
}

- (void)setupAdmob
{
    self.interstitial = [self createAndLoadInterstitial];
    self.connectAfterAdDismiss = NO;
}

- (void)setupVPN
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
            _headerView.triggered = (_tunelProviderManager.connection.status == NEVPNStatusConnected);
        }];
        
    }];
    if([ConfigManager sharedManager].usefreeShadowSocks) {
        [self.view addSubview:_hud];
        [_hud showAnimated:YES];
        [[ConfigManager sharedManager] asyncFetchFreeConfig:YES withCompletion:^(NSError *error) {
            [_hud hideAnimated:YES];
        }];
    }
}

- (void)onAddConfigBtnClicked:(id)sender
{
    AddConfigViewController *vc = [[AddConfigViewController alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
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
    if(section == 2) {
        return 20;
    } else {
        return 55;
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[SectionHeaderView reuseIdentifier]];
    if(section == 0) {
        headerView.text = @"选择配置";
    } else if(section == 1) {
        headerView.text = @"致谢";
    } else {
        return nil;
    }
    return headerView;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) wself = self;
    if(indexPath.row == 0) {
        UITableViewRowAction *updateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"跟新" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [wself.view addSubview:_hud];
            [_hud showAnimated:YES];
            [[ConfigManager sharedManager] asyncFetchFreeConfig:YES withCompletion:^(NSError *error) {
                [_hud hideAnimated:YES];
            }];
        }];
        return @[updateAction];
    } else {
        UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            AddConfigViewController *vc = [[AddConfigViewController alloc] initWithNibName:nil bundle:nil];
            vc.delegate = wself;
            vc.isEditting = YES;
            vc.index = indexPath.row - 1;
            UINavigationController *navi = [[UINavigationController alloc] initWithNavigationBarClass:[TransparentNavigationBar class] toolbarClass:nil];
            [navi pushViewController:vc animated:NO];
            [wself presentViewController:navi animated:YES completion:nil];
        }];
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [[ConfigManager sharedManager] deleteConfig:indexPath.row - 1];
            [wself.tableView reloadData];
        }];
        return @[deleteAction, editAction];
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if(section == 0) {
        if(row == 0) {
            [ConfigManager sharedManager].usefreeShadowSocks = YES;
        } else {
            [ConfigManager sharedManager].usefreeShadowSocks = NO;
            [ConfigManager sharedManager].selectedShadowSocksIndex = row - 1;
        }
        [self restartShadowsocksService];
        [self.tableView reloadData];
    } else if(section == 1) {
        NSString *fileName;
        if(row == 0) {
            fileName = @"Pods-SW-ShadowsocksSW-acknowledgements";
        } else if(row == 1) {
            fileName = @"Pods-SW-PacketTunnelProvider-acknowledgements";
        }
        VTAcknowledgementsViewController *viewController = [[VTAcknowledgementsViewController alloc] initWithFileNamed:fileName];
        viewController.headerText = @"code for fun";
        viewController.navigationItem.title = @"致谢";
        viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[IonIcons imageWithIcon:ion_close_round size:20 color:[UIColor greenColor]] style:UIBarButtonItemStylePlain target:viewController action:@selector(dismissViewController:)];
        viewController.tableView.backgroundColor = [UIColor blackColor];
        viewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [viewController.tableView registerClass:[CommonTableViewCell class] forCellReuseIdentifier:@"Cell"];
        UINavigationController *navi = [[UINavigationController alloc] initWithNavigationBarClass:[TransparentNavigationBar class] toolbarClass:nil];
        [navi pushViewController:viewController animated:NO];
        [self presentViewController:navi animated:YES completion:nil];
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if(section == 0) {
        return [ConfigManager sharedManager].shadowSocksConfigs.count + 1;
    } else if(section == 1) {
        return 2;
    } else if (section == 2) {
        return 1;
    }
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        return YES;
    }
    return NO;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        return [self cellForShadwoSocksConfigAtIndex:indexPath.row];
    } else if(indexPath.section == 1) {
        return [self cellForAcknowlagementAtIndex:indexPath.row];
    } else if(indexPath.section == 2) {
        return [self cellForVersion];
    }
    return nil;
}

- (UITableViewCell *)cellForShadwoSocksConfigAtIndex:(NSInteger)index
{
    ShadowSocksConfig *config;
    if(index == 0) {
        config = [[ShadowSocksConfig alloc] init];
        config.configName = @"免费线路";
    } else {
        config = [ConfigManager sharedManager].shadowSocksConfigs[index - 1];
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ShadowSocksConfigCell"];
    cell.imageView.image = [IonIcons imageWithIcon:ion_earth size:16 color:[UIColor greenColor]];
    cell.textLabel.text = config.configName.length ? config.configName : config.ssServerAddress;
    BOOL isSelected = NO;
    if([ConfigManager sharedManager].usefreeShadowSocks) {
        if(index == 0) isSelected = YES;
    } else {
        if(index - 1 == [ConfigManager sharedManager].selectedShadowSocksIndex) isSelected = YES;
    }
    if(isSelected) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[IonIcons imageWithIcon:ion_paper_airplane size:18 color:[UIColor greenColor]]];
    } else {
        cell.accessoryView = nil;
    }
    cell.userInteractionEnabled = YES;
    return cell;
}

- (UITableViewCell *)cellForAcknowlagementAtIndex:(NSInteger)index
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Acknowlagement"];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[IonIcons imageWithIcon:ion_ios_arrow_right size:18 color:[UIColor greenColor]]];
    NSString *title;
    if(index == 0) {
        title = @"ShadowsocksSW";
    } else {
        title = @"PacketTunnel";
    }
    cell.textLabel.text = title;
    cell.userInteractionEnabled = YES;
    return cell;
}

- (UITableViewCell *)cellForVersion
{
    ConfigCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Version"];
    cell.userInteractionEnabled = NO;
    cell.keyLabel.text = @"版本";
    cell.valueTextField.text = [NSString stringWithFormat:@"%@.%@", [ConfigManager sharedManager].version, [ConfigManager sharedManager].build];
    return cell;
}

#pragma mark - AddConfigViewControllerDelegate
- (void)addConfigSuccess
{
    [self.tableView reloadData];
}

- (void)editConfigSuccess:(NSInteger)index
{
    [self.tableView reloadData];
}

#pragma mark - HeaderViewDelegate
- (void)triggerStateChanged
{
    if(![ConfigManager sharedManager].usefreeShadowSocks && [ConfigManager sharedManager].shadowSocksConfigs.count <= 0) {
        [self.view makeToast:@"请选择一个配置"
                    duration:1.5
                    position:CSToastPositionTop];
        return;
    }
    BOOL triggered = !_headerView.triggered;
    if(triggered) {
        if([ConfigManager sharedManager].usefreeShadowSocks && [self.interstitial isReady]) {
            self.connectAfterAdDismiss = YES;
            [self.interstitial presentFromRootViewController:self];
        } else {
            [self startShadowsocksService];
        }
    } else {
        _headerView.triggered = NO;
        [self stopShadowsocksService];
    }
}

#pragma mark - GADInterstitialDelegate

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
    if(_tunelProviderManager.connection.status != NEVPNStatusConnected && self.connectAfterAdDismiss) {
        [self startShadowsocksService];
    }
}

- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial =
    [[GADInterstitial alloc] initWithAdUnitID:[ConfigManager sharedManager].adUnitID];
    interstitial.delegate = self;
    GADRequest *request = [GADRequest request];
    //request.testDevices = @[ kGADSimulatorID, @"ac1b4824152f925c6ef853f716f08cd5" ];
    [interstitial loadRequest:request];
    
    return interstitial;
}

- (void)doStartAnimation:(void(^)())completion
{
    NSInteger index = 0;
    if(![ConfigManager sharedManager].usefreeShadowSocks) {
        index = [ConfigManager sharedManager].selectedShadowSocksIndex + 1;
    }
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGRect startFrame = [cell convertRect:cell.accessoryView.frame toView:self.tableView];
    CGRect endFrame = [_headerView convertRect:_headerView.triggerBtn.frame toView:self.tableView];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor greenColor]]];
    imageView.frame = startFrame;
    [self.tableView addSubview:imageView];
    [UIView animateWithDuration:0.8f animations:^() {
        imageView.frame = endFrame;
    }completion:^(BOOL finished) {
        [imageView removeFromSuperview];
        if(completion) completion();
    }];
}

- (void)doStopAnimation:(void(^)())completion
{
    NSInteger index = 0;
    if(![ConfigManager sharedManager].usefreeShadowSocks) {
        index = [ConfigManager sharedManager].selectedShadowSocksIndex + 1;
    }
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGRect startFrame = [_headerView convertRect:_headerView.triggerBtn.frame toView:self.tableView];
    CGRect endFrame = [cell convertRect:cell.accessoryView.frame toView:self.tableView];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor greenColor]]];
    imageView.frame = startFrame;
    [self.tableView addSubview:imageView];
    [UIView animateWithDuration:0.8f animations:^() {
        imageView.frame = endFrame;
    }completion:^(BOOL finished) {
        [imageView removeFromSuperview];
        if(completion) completion();
    }];
}

- (void)startShadowsocksServiceImediately
{
    _headerView.triggered = YES;
    [ConfigManager sharedManager].canActivePacketTunnel = YES;
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
                    if(error) {
                        _headerView.triggered = NO;
                        [ConfigManager sharedManager].canActivePacketTunnel = NO;
                        [self.view makeToast:@"启动代理服务失败"
                                    duration:1.5
                                    position:CSToastPositionTop];
                    }
                } else {
                    _headerView.triggered = NO;
                    [ConfigManager sharedManager].canActivePacketTunnel = NO;
                }
            }
        }];
        
    }];
}

- (void)startShadowsocksService
{
    _headerView.userInteractionEnabled = NO;
    [self doStartAnimation:^() {
        _headerView.userInteractionEnabled = YES;
        [self startShadowsocksServiceImediately];
    }];
}

- (void)stopShadowsocksServiceImediately
{
    if(_tunelProviderManager) {
        [_tunelProviderManager.connection stopVPNTunnel];
    } else {
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
                if(_tunelProviderManager.connection.status == NEVPNStatusConnected) {
                    [_tunelProviderManager.connection stopVPNTunnel];
                    [ConfigManager sharedManager].canActivePacketTunnel = NO;
                }
            }];
            
        }];
    }
}

- (void)stopShadowsocksService
{
    _headerView.userInteractionEnabled = NO;
    [self doStopAnimation:^() {
        _headerView.userInteractionEnabled = YES;
        [self stopShadowsocksServiceImediately];
    }];
}

- (void)restartShadowsocksService
{
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVPNContectNotification:) name:NEVPNConfigurationChangeNotification object:nil];
    [self stopShadowsocksServiceImediately];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startShadowsocksServiceImediately];
    });
    
}

- (void)onVPNContectNotification:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEVPNConfigurationChangeNotification object:nil];
    [self startShadowsocksServiceImediately];
}

#pragma mark - Notification
//- (void)onUIApplicationWillResignActiveNotification:(NSNotification *)note
//{
//    self.interstitial = [self createAndLoadInterstitial];
//}

- (void)onUIApplicationWillEnterForegroundNotification:(NSNotification *)note
{
    if(self.interstitial.isReady) {
        self.connectAfterAdDismiss = NO;
        [self.interstitial presentFromRootViewController:self];
    }
}

@end
