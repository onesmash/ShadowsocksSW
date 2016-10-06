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
        _triggerBtn.bounds = CGRectMake(0, 0, 50, 50);
        [_triggerBtn setImage:[IonIcons imageWithIcon:ion_paper_airplane size:50 color:[UIColor redColor]] forState:UIControlStateNormal];
        [self addSubview:_triggerBtn];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _triggerBtn.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

@end
