//
//  AddConfigViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "AddConfigViewController.h"
#import "ConfigCell.h"
#import "ConfigEncryptionMethodSelectCell.h"
#import "NSString+Util.h"
#import "ConfigManager.h"
#import "LogViewController.h"
#import "TransparentNavigationBar.h"
#import <IonIcons.h>

typedef enum {
    kConfigItemTypeServerAddress,
    kConfigItemTypeServerPort,
    kConfigItemTypePassword,
    kConfigItemTypeEncryptionMethod,
    kConfigItemTypeConfigName
} ConfigItemType;

@interface AddConfigViewController () <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIPickerView *encryptionMethodPickerView;
@property (nonatomic, assign) NSInteger selectedEncryptionMethodIndex;
@property (nonatomic, assign) BOOL isSettingEncryptionMethod;
@property (nonatomic, strong) NSArray *encryptionMethods;

@end

@implementation AddConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _encryptionMethods = @[@"rc4",
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
                           @"seed-cfb"];
    [self setupNavigationBar];
    [self setupView];
    _selectedEncryptionMethodIndex = 3;
    _isSettingEncryptionMethod = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUIKeyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUITextFieldTextDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:nil];
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
    self.navigationItem.title = @"添加配置";
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn addTarget:self action:@selector(onCloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [closeBtn setImage:[IonIcons imageWithIcon:ion_close_round size:20 color:[UIColor greenColor]] forState:UIControlStateNormal];
    [closeBtn sizeToFit];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [saveBtn addTarget:self action:@selector(onSaveBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [saveBtn setImage:[IonIcons imageWithIcon:ion_checkmark_round size:22 color:[UIColor greenColor]] forState:UIControlStateNormal];
    [saveBtn sizeToFit];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)setupView
{
    self.view.backgroundColor = [UIColor blackColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"ConfigCell" bundle:nil] forCellReuseIdentifier:@"ConfigCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ConfigEncryptionMethodSelectCell" bundle:nil] forCellReuseIdentifier:@"ConfigEncryptionMethodSelectCell"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.encryptionMethodPickerView.delegate = self;
    self.encryptionMethodPickerView.dataSource = self;
    self.encryptionMethodPickerView.$top = self.view.$height;
}

- (void)onCloseBtnClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^() {
        if([_delegate respondsToSelector:@selector(editConfigCancelled)]) {
            [_delegate editConfigCancelled];
        }
    }];
}

- (void)onSaveBtnClicked:(id)sender
{
    ConfigCell *serverAddressConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeServerAddress inSection:0]];
    ConfigCell *serverPortConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeServerPort inSection:0]];
    ConfigCell *passwordConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypePassword inSection:0]];
    ConfigEncryptionMethodSelectCell *encryptionMethodSelectCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeEncryptionMethod inSection:0]];
    ConfigCell *configNameConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeConfigName inSection:0]];
    NSString *serverAddress = [serverAddressConfigCell.valueTextField.text $trim];
    NSString *serverPort = [serverPortConfigCell.valueTextField.text $trim];
    NSString *password = [passwordConfigCell.valueTextField.text $trim];
    NSString *encryptionMethod = encryptionMethodSelectCell.encryptionMethodLabel.text;
    NSString *configName = [configNameConfigCell.valueTextField.text $trim];
    ShadowSocksConfig *config = [[ShadowSocksConfig alloc] init];
    config.ssServerAddress = serverAddress;
    config.ssServerPort = serverPort;
    config.password = password;
    config.encryptionMethod = encryptionMethod;
    config.configName = configName;
    if(_isEditting) {
        [[ConfigManager sharedManager] replaceConfig:_index withConfig:config];
    } else {
        [[ConfigManager sharedManager] addConfig:config];
    }
    [self dismissViewControllerAnimated:YES completion:^() {
        if(_isEditting) {
            if([_delegate respondsToSelector:@selector(editConfigSuccess:)]) {
                [_delegate editConfigSuccess:_index];
            }
        } else {
            if([_delegate respondsToSelector:@selector(addConfigSuccess)]) {
                [_delegate addConfigSuccess];
            }
        }
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConfigItemType itemType = (ConfigItemType)indexPath.row;
    if(itemType == kConfigItemTypeEncryptionMethod) {
        _isSettingEncryptionMethod = !_isSettingEncryptionMethod;
        if(_isSettingEncryptionMethod) {
            [self.encryptionMethodPickerView selectRow:self.selectedEncryptionMethodIndex inComponent:0 animated:NO];
            [UIView animateWithDuration:0.4f animations:^() {
                self.encryptionMethodPickerView.$bottom = self.view.$height;
            }];
        } else {
            [UIView animateWithDuration:0.4f animations:^() {
                self.encryptionMethodPickerView.$top = self.view.$height;
            }];
        }
        
    } else {
        if(_isSettingEncryptionMethod) {
            _isSettingEncryptionMethod = NO;
            [UIView animateWithDuration:0.4f animations:^() {
                self.encryptionMethodPickerView.$top = self.view.$height;
            }];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConfigItemType itemType = (ConfigItemType)indexPath.row;
    switch (itemType) {
        case kConfigItemTypeServerAddress: {
            ConfigCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConfigCell"];
            cell.keyLabel.text = @"服务器";
            cell.valueTextField.placeholder = @"必填";
            if(_isEditting) {
                ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[_index];
                cell.valueTextField.text = config.ssServerAddress;
            }
            return cell;
        } break;
        case kConfigItemTypeServerPort: {
            ConfigCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConfigCell"];
            cell.keyLabel.text = @"端口";
            cell.valueTextField.placeholder = @"必填，1-65535";
            if(_isEditting) {
                ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[_index];
                cell.valueTextField.text = config.ssServerPort;
            }
            return cell;
        } break;
        case kConfigItemTypePassword: {
            ConfigCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConfigCell"];
            cell.keyLabel.text = @"密码";
            cell.valueTextField.placeholder = @"必填";
            if(_isEditting) {
                ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[_index];
                cell.valueTextField.text = config.password;
            }
            return cell;
        } break;
        case kConfigItemTypeEncryptionMethod: {
            ConfigEncryptionMethodSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConfigEncryptionMethodSelectCell"];
            if(_isEditting) {
                ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[_index];
                [_encryptionMethods enumerateObjectsUsingBlock:^(NSString *method, NSUInteger index, BOOL *stop) {
                    if([config.encryptionMethod isEqualToString:method]) {
                        _selectedEncryptionMethodIndex = _index;
                        *stop = YES;
                    }
                }];
            }
            return cell;
        } break;
        case kConfigItemTypeConfigName: {
            ConfigCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ConfigCell"];
            cell.keyLabel.text = @"备注名";
            cell.valueTextField.placeholder = @"可选";
            if(_isEditting) {
                ShadowSocksConfig *config = [ConfigManager sharedManager].shadowSocksConfigs[_index];
                cell.valueTextField.text = config.configName;
            }
            return cell;
        } break;
        default:
            return nil;
    }
}

#pragma mark - UIPickerViewDelegate
- (nullable NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor greenColor]};
    NSString *text = _encryptionMethods[row];
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedEncryptionMethodIndex = row;
    ConfigEncryptionMethodSelectCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeEncryptionMethod inSection:0]];
    cell.encryptionMethodLabel.text = _encryptionMethods[row];
}
#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 13;
}

#pragma mark - Notification
- (void)onUIKeyboardWillShowNotification:(NSNotification *)note
{
    _isSettingEncryptionMethod = NO;
    [UIView animateWithDuration:0.4f animations:^() {
        self.encryptionMethodPickerView.$top = self.view.$height;
    }];
}

- (void)onUITextFieldTextDidChangeNotification:(NSNotification *)note
{
    ConfigCell *serverAddressConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeServerAddress inSection:0]];
    ConfigCell *serverPortConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeServerPort inSection:0]];
    ConfigCell *passwordConfigCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypePassword inSection:0]];
    if([serverAddressConfigCell.valueTextField.text $trim].length && [serverPortConfigCell.valueTextField.text $trim].length && [passwordConfigCell.valueTextField.text $trim].length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        ConfigCell *configNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kConfigItemTypeConfigName inSection:0]];
        if([configNameCell.valueTextField.text isEqualToString:@"@123456789"]) {
            LogViewController *vc = [[LogViewController alloc] initWithNibName:nil bundle:nil];
            UINavigationController *navi = [[UINavigationController alloc] initWithNavigationBarClass:[TransparentNavigationBar class] toolbarClass:nil];
            [navi pushViewController:vc animated:NO];
            [self presentViewController:navi animated:YES completion:nil];
        }
    }
}

@end
