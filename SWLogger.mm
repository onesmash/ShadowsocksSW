//
//  SWLogger.m
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/16.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "SWLogger.h"
#import "ConfigManager.h"
#import <Foundation/Foundation.h>

std::string GetLogFile()
{
    @autoreleasepool {
#if defined(TUNNEL_RPOVIDER)
        return [ConfigManager sharedManager].tunnelProviderLogFile.UTF8String;
#else
        return [ConfigManager sharedManager].mainAppLogFile.UTF8String;
#endif
    }
}

#ifdef DEBUG
WukongBase::Base::Logger logger(GetLogFile(), 4 * 1024 *1024, 3, WukongBase::Base::Logger::kLogLevelTrace);
#else
WukongBase::Base::Logger logger(GetLogFile(), 4 * 1024 *1024, 3);
#endif
