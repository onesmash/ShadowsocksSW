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
#import "SWUITextView.h"
#import <IonIcons.h>
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, AddConfigViewControllerDelegate, HeaderViewDelegate> {
    
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) HeaderView *headerView;
@property (nonatomic, strong) NETunnelProviderManager *tunelProviderManager;
@property (strong, nonatomic) IBOutlet UITextView *logView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [self setupView];
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
    _headerView = [[HeaderView alloc] init];
    _headerView.delegate = self;
    self.tableView.tableHeaderView = _headerView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[SectionHeaderView class] forHeaderFooterViewReuseIdentifier:[SectionHeaderView reuseIdentifier]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ShadowSocksConfigCell"];
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)onVPNContectNotification:(NSNotification *)note
{
    
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
    return 55;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SectionHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[SectionHeaderView reuseIdentifier]];
    headerView.text = @"选择配置";
    return headerView;
}

- (nullable NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) wself = self;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if(row == 0) {
        [ConfigManager sharedManager].usefreeShadowSocks = YES;
    } else {
        [ConfigManager sharedManager].usefreeShadowSocks = NO;
        [ConfigManager sharedManager].selectedShadowSocksIndex = row - 1;
    }
    [self.tableView reloadData];
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    if(section == 0) {
        return [ConfigManager sharedManager].shadowSocksConfigs.count + 1;
    } else {
        return 0;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0) {
        return NO;
    } else {
        return YES;
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
    cell.textLabel.textColor = [UIColor greenColor];
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
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
- (void)triggerStateChanged:(BOOL)triggered
{
    if(triggered) {
        [[ConfigManager sharedManager] asyncFetchFreeConfig:nil];
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
                        _headerView.triggered = NO;
                    }
                }
            }];
            
        }];
    } else {
        [_tunelProviderManager.connection stopVPNTunnel];
    }
}

- (void)onDisplayLink:(CADisplayLink *)link
{
    NSString *path = [NSString stringWithFormat:@"%@.txt", [ConfigManager sharedManager].tunnelProviderLogFile];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error;
        NSString *log = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        _logView.text = log;
    }
        
    
}

@end
