//
//  TransparentNavigationBar.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/29.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "TransparentNavigationBar.h"

@implementation TransparentNavigationBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
        self.tintColor = [UIColor clearColor];
        [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [self setShadowImage:[UIImage new]];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
