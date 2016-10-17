//
//  AddConfigViewController.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddConfigViewControllerDelegate <NSObject>

@optional
- (void)editConfigCancelled;
- (void)addConfigSuccess;
- (void)editConfigSuccess:(NSInteger)index;

@end

@interface AddConfigViewController : UIViewController

@property (nonatomic, weak) id<AddConfigViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isEditting;
@property (nonatomic, assign) NSInteger index;

@end
