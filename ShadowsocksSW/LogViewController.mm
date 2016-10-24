//
//  LogViewController.m
//  ShadowsocksSW
//
//  Created by Xuhui on 20/10/2016.
//  Copyright © 2016 Xuhui. All rights reserved.
//

#import "LogViewController.h"
#import "ConfigManager.h"
#import "SWLogger.h"
#import <IonIcons.h>

@interface LogViewController ()
@property (strong, nonatomic) IBOutlet UITextView *logView;

@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[IonIcons imageWithIcon:ion_close_round size:20 color:[UIColor greenColor]] style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewController:)];
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onDisplayLink:(CADisplayLink *)link
{
    SWLOG_FLUSH();
    _logView.text = [ConfigManager sharedManager].packetTunnelLog;
}

- (void)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
