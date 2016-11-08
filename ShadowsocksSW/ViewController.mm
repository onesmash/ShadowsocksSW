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
#import "SmartProxySettingCell.h"
#import <MMWormhole.h>
#import <UIView+Toast.h>
#import <IonIcons.h>
#import <Firebase.h>
#import <MBProgressHUD.h>
#import <Reachability.h>
#import <QRCodeReaderViewController.h>
#import <VTAcknowledgementViewController.h>
#import <VTAcknowledgementsViewController.h>
#import <NetworkExtension/NetworkExtension.h>

enum SectionType {
    kSectionTypeConfig,
    kSectionTypeSetting,
    kSectionTypeAcknowledgement,
    kSectionTypeVersion,
    kSectionTypeMaxEnum
};

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, AddConfigViewControllerDelegate, HeaderViewDelegate, GADInterstitialDelegate, QRCodeReaderDelegate> {
    
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) HeaderView *headerView;
@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (nonatomic, strong) GADInterstitial *interstitial;
@property (nonatomic, assign) BOOL connectAfterAdDismiss;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) MMWormhole *wormhole;
@property (nonatomic, strong) QRCodeReader *reader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWormhole];
    [self setupAdmob];
    [self setupNavigationBar];
    [self setupView];
    [self setupVPN];
    [self showGudieTip];
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
    UIButton *scanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [scanBtn addTarget:self action:@selector(onScanBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [scanBtn setImage:[IonIcons imageWithIcon:ion_qr_scanner size:25 color:[UIColor greenColor]] forState:UIControlStateNormal];
    [scanBtn sizeToFit];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:scanBtn];
    
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
    [self.tableView registerNib:[UINib nibWithNibName:@"SmartProxySettingCell" bundle:nil] forCellReuseIdentifier:@"SmartProxy"];
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
            _tunelProviderManager.localizedDescription = [ConfigManager sharedManager].displayName;
            _tunelProviderManager.protocolConfiguration = [NETunnelProviderProtocol new];
        }
        _tunelProviderManager.onDemandEnabled = NO;
        _tunelProviderManager.protocolConfiguration.serverAddress = [ConfigManager sharedManager].displayName;
        _tunelProviderManager.enabled = YES;
        [_tunelProviderManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
            _headerView.triggered = (_tunelProviderManager.connection.status == NEVPNStatusConnected);
        }];
        
    }];
}

- (void)setupWormhole
{
    __weak typeof(self) wself = self;
    [self.wormhole listenForMessageWithIdentifier:kWormholeNeedShowFreeShadwosocksConfigUpdateTipNotification listener:^(id message) {
        [wself showFreeConfigUpdateTip];
    }];
}

- (QRCodeReader *)reader
{
    if(!_reader) {
        _reader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    }
    return _reader;
}

- (MMWormhole *)wormhole
{
    if(!_wormhole) {
        _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:kSharedGroupIdentifier
                                                         optionalDirectory:@"wormhole"];
    }
    return _wormhole;
}

- (void)showGudieTip
{
    [self.view makeToast:@"点击灰色飞机，开启奇妙路程"
                duration:4
                position:CSToastPositionTop];
}

- (void)showFreeConfigUpdateTip
{
    if([ConfigManager sharedManager].needShowFreeShadowSocksConfigsUpdateTip) {
        [self.view makeToast:@"如一直无法使用免费线路上网，请左滑“免费线路”，更新配置"
                    duration:5
                    position:CSToastPositionTop];
    }
}

- (void)showForceFreeConfigUpdateTip
{
    [self.view makeToast:@"请左滑“免费线路”，更新配置"
                duration:4
                position:CSToastPositionTop];
}

- (void)showFreeConfigUpdateFailedTip
{
    if([ConfigManager sharedManager].needShowFreeShadowSocksConfigsUpdateTip) {
        [self.view makeToast:@"免费线路配置更新失败"
                    duration:2
                    position:CSToastPositionTop];
    }
}

- (void)showEncryptionMethodNotSupportTip
{
    [self.view makeToast:@"不支持的加密方式"
                duration:2
                position:CSToastPositionTop];
}

- (void)showQRCodeNotSupportTip
{
    [self.view makeToast:@"不支持的二维码"
                duration:2
                position:CSToastPositionTop];
}

- (void)showSmartProxyTip
{
    [self.view makeToast:@"关闭智能代理，国内网络的访问也会经过代理"
                duration:2
                position:CSToastPositionTop];
}

- (void)onScanBtnClicked:(id)sender
{
    QRCodeReaderViewController *vc = [QRCodeReaderViewController readerWithCancelButtonTitle:@"取消" codeReader:self.reader startScanningAtLoad:YES showSwitchCameraButton:YES showTorchButton:YES];
    vc.modalPresentationStyle = UIModalPresentationFormSheet;
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:NULL];
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
    if(section == kSectionTypeVersion) {
        return 20;
    } else {
        return 55;
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[SectionHeaderView reuseIdentifier]];
    if(section == kSectionTypeConfig) {
        headerView.text = @"选择线路";
    } else if(section == kSectionTypeAcknowledgement) {
        headerView.text = @"致谢";
    } else if(section == kSectionTypeSetting) {
        headerView.text = @"设置";
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
        UITableViewRowAction *updateAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"更新" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            if([ConfigManager sharedManager].usefreeShadowSocks && _tunelProviderManager && _tunelProviderManager.connection.status == NEVPNStatusConnected) {
                [self.view makeToast:@"无法在开启免费线路模式下更新配置"
                            duration:1.5
                            position:CSToastPositionTop];
            } else {
                [wself.view addSubview:_hud];
                [_hud showAnimated:YES];
                [[ConfigManager sharedManager] asyncFetchFreeConfig:YES withCompletion:^(NSError *error) {
                    [_hud hideAnimated:YES];
                    if(error) {
                        [wself showFreeConfigUpdateFailedTip];
                    }
                }];
            }
            
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
    if(section == kSectionTypeConfig) {
        if(row == 0) {
            [ConfigManager sharedManager].usefreeShadowSocks = YES;
        } else {
            [ConfigManager sharedManager].usefreeShadowSocks = NO;
            [ConfigManager sharedManager].selectedShadowSocksIndex = row - 1;
        }
        if([ConfigManager sharedManager].usefreeShadowSocks && [ConfigManager sharedManager].freeShadowSocksConfigs.count <= 0) {
            [self showForceFreeConfigUpdateTip];
        }
        [self restartShadowsocksService];
        [self.tableView reloadData];
    } else if(section == kSectionTypeAcknowledgement) {
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
    return kSectionTypeMaxEnum;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if(section == kSectionTypeConfig) {
        return [ConfigManager sharedManager].shadowSocksConfigs.count + 1;
    } else if(section == kSectionTypeAcknowledgement) {
        return 2;
    } else if (section == kSectionTypeVersion) {
        return 1;
    } else if (section == kSectionTypeSetting) {
        return 1;
    }
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kSectionTypeConfig) {
        return YES;
    }
    return NO;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kSectionTypeConfig) {
        return [self cellForShadwoSocksConfigAtIndex:indexPath.row];
    } else if(indexPath.section == kSectionTypeAcknowledgement) {
        return [self cellForAcknowlagementAtIndex:indexPath.row];
    } else if(indexPath.section == kSectionTypeVersion) {
        return [self cellForVersion];
    } else if(indexPath.section == kSectionTypeSetting) {
        return [self cellforSettingAtIndex:indexPath.row];
    }
    return nil;
}

- (UITableViewCell *)cellforSettingAtIndex:(NSInteger)index
{
    SmartProxySettingCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"SmartProxy"];
    [cell.smartProxySwitch addTarget:self action:@selector(onSmartProxySettingStatusChanged:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (UITableViewCell *)cellForShadwoSocksConfigAtIndex:(NSInteger)index
{
    ShadowSocksConfig *config;
    if(index == 0) {
        config = [ConfigManager sharedManager].freeShadowSocksConfigs.count ?  [[ConfigManager sharedManager].freeShadowSocksConfigs objectAtIndex:[ConfigManager sharedManager].selectedFreeShadowSocksIndex] : [[ShadowSocksConfig alloc] init];
        config.configName = @"免费线路";
    } else {
        config = [ConfigManager sharedManager].shadowSocksConfigs[index - 1];
    }
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ShadowSocksConfigCell"];
    cell.imageView.image = config.country.length > 0 ? [UIImage imageNamed:config.country] : [IonIcons imageWithIcon:ion_earth size:16 color:[UIColor greenColor]];
    cell.imageView.$size = CGSizeMake(16, 16);
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
        title = @"DarkNetSW";
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

#pragma mark - QRCodeReaderDelegate
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        ShadowSocksConfig *config;
        NSArray<NSString *> *components = [result componentsSeparatedByString:@"://"];
        if(components.count == 2 && [[components objectAtIndex:0] isEqualToString:@"ss"]) {
            NSString *base64Str = components[1];
            NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
            
            NSString *configStr = [NSString stringWithFormat:@"ss://%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            NSURL *url = [NSURL URLWithString:configStr];
            if([url.scheme isEqualToString:@"ss"]) {
                config = [[ShadowSocksConfig alloc] init];
                config.ssServerAddress = url.host;
                config.ssServerPort = url.port.stringValue;
                config.encryptionMethod = url.user;
                config.password = url.password;
            }
        }
        if(config) {
            if([[ConfigManager sharedManager] checkEncryptionMethodSupport:config.encryptionMethod]) {
                [[ConfigManager sharedManager] addConfig:config];
                [self.tableView reloadData];
            } else {
                [self showEncryptionMethodNotSupportTip];
            }
        } else {
            [self showQRCodeNotSupportTip];
        }
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void)startShadowsocksServiceImediately:(void(^)(NSError *error))completionHandler
{
    _headerView.triggered = YES;
    [ConfigManager sharedManager].canActivePacketTunnel = YES;
    if([ConfigManager sharedManager].usefreeShadowSocks) {
        [ConfigManager sharedManager].selectedFreeShadowSocksIndex = arc4random_uniform((int32_t)[ConfigManager sharedManager].freeShadowSocksConfigs.count);
        [self.tableView reloadData];
    }
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> *managers, NSError *error) {
        if(error && completionHandler) {
            completionHandler(error);
            return;
        }
        if(managers.count > 0) {
            _tunelProviderManager = managers.firstObject;
        } else {
            _tunelProviderManager = [[NETunnelProviderManager alloc] init];
            _tunelProviderManager.localizedDescription = [ConfigManager sharedManager].displayName;
            _tunelProviderManager.protocolConfiguration = [NETunnelProviderProtocol new];
        }
        _tunelProviderManager.onDemandEnabled = NO;
        _tunelProviderManager.protocolConfiguration.serverAddress = [ConfigManager sharedManager].displayName;
        _tunelProviderManager.enabled = YES;
        [_tunelProviderManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
            if(error && completionHandler) {
                completionHandler(error);
                return;
            }
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
                if(completionHandler) completionHandler(error);
            }
        }];
        
    }];
}

- (void)startShadowsocksService
{
    if([ConfigManager sharedManager].usefreeShadowSocks && [ConfigManager sharedManager].freeShadowSocksConfigs.count <= 0) {
        [self showForceFreeConfigUpdateTip];
    } else {
        _headerView.userInteractionEnabled = NO;
        [self doStartAnimation:^() {
            _headerView.userInteractionEnabled = YES;
            [self startShadowsocksServiceImediately:nil];
        }];
    }
}

- (void)stopShadowsocksServiceImediately:(void(^)(NSError *error))completionHandler
{
    if(_tunelProviderManager) {
        [_tunelProviderManager.connection stopVPNTunnel];
        _headerView.triggered = NO;
        [ConfigManager sharedManager].canActivePacketTunnel = NO;
        if(completionHandler) completionHandler(nil);
    } else {
        [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> *managers, NSError *error) {
            if(error && completionHandler) {
                completionHandler(error);
                return;
            }
            if(managers.count > 0) {
                _tunelProviderManager = managers.firstObject;
            } else {
                _tunelProviderManager = [[NETunnelProviderManager alloc] init];
                _tunelProviderManager.localizedDescription = [ConfigManager sharedManager].displayName;
                _tunelProviderManager.protocolConfiguration = [NETunnelProviderProtocol new];
            }
            _tunelProviderManager.onDemandEnabled = NO;
            _tunelProviderManager.protocolConfiguration.serverAddress = [ConfigManager sharedManager].displayName;
            _tunelProviderManager.enabled = YES;
            [_tunelProviderManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                if(_tunelProviderManager.connection.status == NEVPNStatusConnected) {
                    [_tunelProviderManager.connection stopVPNTunnel];
                    _headerView.triggered = NO;
                    [ConfigManager sharedManager].canActivePacketTunnel = NO;
                }
                if(completionHandler) completionHandler(error);
            }];
            
        }];
    }
}

- (void)stopShadowsocksService
{
    _headerView.userInteractionEnabled = NO;
    [self doStopAnimation:^() {
        _headerView.userInteractionEnabled = YES;
        [self stopShadowsocksServiceImediately:nil];
    }];
}

- (void)restartShadowsocksService
{
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVPNContectNotification:) name:NEVPNConfigurationChangeNotification object:nil];
    [self stopShadowsocksServiceImediately:^(NSError *error) {
        if(!error) {
            if([ConfigManager sharedManager].usefreeShadowSocks && [ConfigManager sharedManager].freeShadowSocksConfigs.count <= 0) {
                [self showForceFreeConfigUpdateTip];
            } else {
                [self.view makeToast:@"正在切换配置，文字消失前不要退出应用"
                            duration:4
                            position:CSToastPositionTop];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self startShadowsocksServiceImediately:nil];
                });
            }
        } else {
            [self.view makeToast:@"服务重启失败"
                        duration:2
                        position:CSToastPositionTop];
        }
    }];
    
}

- (void)onVPNContectNotification:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEVPNConfigurationChangeNotification object:nil];
    [self startShadowsocksServiceImediately:nil];
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
    [self showFreeConfigUpdateTip];
}

- (void)onSmartProxySettingStatusChanged:(UISwitch *)sender
{
    if(!sender.on) {
        [self showSmartProxyTip];
    }
    [ConfigManager sharedManager].smartProxyEnable = sender.on;
    if(_tunelProviderManager && _tunelProviderManager.connection.status == NEVPNStatusConnected) {
        [self restartShadowsocksService];
    }
}

@end
