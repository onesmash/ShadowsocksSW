//
//  ConfigCell.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWUIKit.h"

@interface ConfigCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *keyLabel;
@property (strong, nonatomic) IBOutlet SWUITextField *valueTextField;

@end
