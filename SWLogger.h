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

//void SWLogInfo(const char* fmt, ...);
//void SWLogWarn(const char* fmt, ...);
//void SWLogError(const char* fmt, ...);

#ifndef DEBUG
extern WukongBase::Base::Logger logger;
 
#define SWLOG_TRACE(...) LOG_TRACE((&logger), __VA_ARGS__)
#define SWLOG_DEBUG(...) LOG_DEBUG((&logger), __VA_ARGS__)
#define SWLOG_INFO(...) LOG_INFO((&logger), __VA_ARGS__)
#define SWLOG_WARN(...) LOG_WARN((&logger), __VA_ARGS__)
#define SWLOG_ERROR(...) LOG_ERROR((&logger), __VA_ARGS__)
#define SWLOG_CRITICAL(...) LOG_CRITICAL((&logger), __VA_ARGS__)
#define SWLOG_FLUSH() logger.flush()
#else
#define SWLOG_TRACE(...) LOG_TRACE((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_DEBUG(...) LOG_DEBUG((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_INFO(...) LOG_INFO((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_WARN(...) LOG_WARN((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_ERROR(...) LOG_ERROR((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_CRITICAL(...) LOG_CRITICAL((&WukongBase::Base::Logger::sharedStderrLogger()), __VA_ARGS__)
#define SWLOG_FLUSH() WukongBase::Base::Logger::sharedStderrLogger().flush()
#endif

#ifdef __cplusplus
}
#endif