//
//  AddConfigViewController.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddConfigViewControllerDelegate <NSObject>

- (void)addConfigCancelled;
- (void)addConfigSuccess;

@end

@interface AddConfigViewController : UIViewController

@end
