//
//  HeaderView.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/4.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "HeaderView.h"
#import <IonIcons.h>

@interface HeaderView ()

@end

@implementation HeaderView

+ (CGFloat)viewHeight
{
    return 150;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, [HeaderView viewHeight])];
    if(self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _triggerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_triggerBtn addTarget:self action:@selector(onTriggerBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        _triggerBtn.bounds = CGRectMake(0, 0, 50, 50);
        [_triggerBtn setImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor grayColor]] forState:UIControlStateNormal];
        [self addSubview:_triggerBtn];
        _triggered = NO;
    }
    return self;
}

- (void)setTriggered:(BOOL)triggered
{
    _triggered = triggered;
    if(_triggered) {
        [_triggerBtn setImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor greenColor]] forState:UIControlStateNormal];
    } else {
        [_triggerBtn setImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor grayColor]] forState:UIControlStateNormal];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _triggerBtn.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

- (void)onTriggerBtnClicked:(id)sender
{
    [_delegate triggerStateChanged];
}

@end
