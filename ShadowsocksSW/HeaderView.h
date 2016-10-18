//
//  HeaderView.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/4.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HeaderViewDelegate <NSObject>

- (void)triggerStateChanged;

@end

@interface HeaderView : UIView
@property (nonatomic, assign) BOOL triggered;
@property (nonatomic, strong) UIButton *triggerBtn;
@property (nonatomic, weak) id<HeaderViewDelegate> delegate;

+ (CGFloat)viewHeight;

@end
