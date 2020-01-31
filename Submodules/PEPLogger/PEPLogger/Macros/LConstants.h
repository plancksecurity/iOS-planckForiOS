//
//  LConstants.h
//  PEPLogger
//
//  Created by Alejandro Gelos on 22/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

#ifndef LConstants_h
#define LConstants_h


#endif /* LConstants_h */

/**
Macros that offer logging funtionality as Logger.swift but for Objective-C.

This Macros were created to automatically get the class, function and line where the method was called.
 */

/**
Logs only when build for DEBUG.
@param error_to_log the error to log.
*/
#define LOG_ERROR_DEBUG(error_to_log)\
[[Logger shared] debugWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Logs only when build for DEBUG.
@param message_to_log a message to log.
*/
#define LOG_MESSAGE_DEBUG(message_to_log)\
[[Logger shared] debugWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Always logs only when build for DEBUG. Logs only in mode `verbose` when build for RELEASE.
@param error_to_log the error to log.
*/
#define LOG_ERROR_INFO(error_to_log)\
[[Logger shared] infoWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Always logs only when build for DEBUG. Logs only in mode `verbose` when build for RELEASE.
@param message_to_log a message to log.
 */
#define LOG_MESSAGE_INFO(message_to_log)\
[[Logger shared] infoWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Always logs.
@param error_to_log the error to log.
*/
#define LOG_ERROR_WARN(error_to_log)\
[[Logger shared] warnWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Always logs.
@param message_to_log a message to log.
 */
#define LOG_MESSAGE_WARN(message_to_log)\
[[Logger shared] warnWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Always logs.
@param error_to_log the error to log.
*/
#define LOG_ERROR(error_to_log)\
[[Logger shared] errorWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Always logs.
@param message_to_log a message to log.
 */
#define LOG_ERRORMESSAGE(message_to_log)\
[[Logger shared] errorWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Always logs. And crash only if build for DEBUG.
@param error_to_log the error to log.
*/
#define LOG_ERROR_AND_CRASH(error_to_log)\
[[Logger shared] errorAndCrashWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Always logs. And crash only if build for DEBUG.
@param message_to_log a message to log.
 */
#define LOG_ERRORMESSAGE_AND_CRASH(message_to_log)\
[[Logger shared] errorAndCrashWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\
