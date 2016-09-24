//
//  SWLogger.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/16.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "SWLogger.h"
#import <Foundation/Foundation.h>

std::string GetLogFile()
{
    @autoreleasepool {
        NSString *path = [NSString stringWithFormat:@"%@/log", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).lastObject];
        return path.UTF8String;
    }
}

#ifdef DEBUG
WukongBase::Base::Logger logger(GetLogFile(), 4 * 1024 *1024, 3, WukongBase::Base::Logger::kLogLevelTrace);
#else
WukongBase::Base::Logger logger(GetLogFile(), 4 * 1024 *1024, 3);
#endif