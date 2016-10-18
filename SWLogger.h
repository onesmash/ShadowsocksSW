//
//  SWLogger.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/9/16.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#import "base/Logger.h"

#ifdef __cplusplus 
extern "C" {
#endif

extern WukongBase::Base::Logger logger;

#if defined(TUNNEL_PROVIDER) || !defined(DEBUG)
#define sink logger
#else
#define sink WukongBase::Base::Logger::sharedStderrLogger()
#endif
    
#define SWLOG_TRACE(...) LOG_TRACE((&sink), __VA_ARGS__)
#define SWLOG_DEBUG(...) LOG_DEBUG((&sink), __VA_ARGS__)
#define SWLOG_INFO(...) LOG_INFO((&sink), __VA_ARGS__)
#define SWLOG_WARN(...) LOG_WARN((&sink), __VA_ARGS__)
#define SWLOG_ERROR(...) LOG_ERROR((&sink), __VA_ARGS__)
#define SWLOG_CRITICAL(...) LOG_CRITICAL((&sink), __VA_ARGS__)
#define SWLOG_FLUSH() sink.flush()

#ifdef __cplusplus
}
#endif
