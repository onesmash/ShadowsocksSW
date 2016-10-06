//
//  SectionHeaderView.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, copy) NSString *text;

+ (NSString *)reuseIdentifier;

@end
