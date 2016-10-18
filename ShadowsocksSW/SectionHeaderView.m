//
//  SectionHeaderView.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "SectionHeaderView.h"
#import "SWUIKit.h"

@interface SectionHeaderView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation SectionHeaderView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if(self) {
        self.backgroundView = nil;
        self.contentView.backgroundColor = [UIColor clearColor];
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont systemFontOfSize:13];
        _label.textColor = [UIColor greenColor];
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews
{
    [_label sizeToFit];
    _label.$top = 33;
    _label.$left = 15;
}

- (void)setText:(NSString *)text
{
    _text = [text copy];
    _label.text = _text;
}

+ (NSString *)reuseIdentifier
{
    return @"SectionHeaderView";
}
@end
