//
//  CommonTableViewCell.m
//  ShadowsocksSW
//
//  Created by Xuhui on 17/10/2016.
//  Copyright © 2016 Xuhui. All rights reserved.
//

#import "CommonTableViewCell.h"
#import <IonIcons.h>

@implementation CommonTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor greenColor];
        self.detailTextLabel.textColor = [UIColor greenColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryView = [UIView new];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
