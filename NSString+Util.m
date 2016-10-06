//
//  NSString+Util.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/10/6.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "NSString+Util.h"

@implementation NSString (Util)

- (NSString *)$trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
