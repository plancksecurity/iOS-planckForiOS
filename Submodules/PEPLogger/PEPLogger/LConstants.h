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
Debug-level messages are intended to be use in a development environment and not in shipping software.
Debug-level messages are only shown in console when debuging but not in Release.
Note that nothing will be store in the device.
@param error_to_log nullable NSError that helps to understand what went wrong. This is the actual error that we get from the
 app (if any). If nil error is pass, empty error information will be added on the log.
@return Nothing returned.
*/
#define LOG_DEBUG_WITH_ERROR(error_to_log)\
[[Logger share] debugWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
 Debug-level messages are intended to be use in a development environment and not in shipping software.
 Debug-level messages are only shown in console when debuging but not in Release.
 Note that nothing will be store in the device.
 @param message_to_log nullable NSString message that helps to understand or gives more details about the log. If nil message,
 empty message information will be added on the log.
@return Nothing returned.
*/
#define LOG_DEBUG_WITH_MESSAGE(message_to_log)\
[[Logger share] debugWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Info-level messages are intended for capturing information that may be helpful, but isn’t essential, for troubleshooting errors.
Info-level messages are store in the device. And also shown in console when debuging but not in Release.
@param error_to_log nullable NSError that helps to understand what went wrong. This is the actual error that we get from the
 app (if any). If nil error is pass, empty error information will be added on the log.
@return Nothing returned.
*/
#define LOG_INFO_WITH_ERROR(error_to_log)\
[[Logger share] infoWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Info-level messages are intended for capturing information that may be helpful, but isn’t essential, for troubleshooting errors.
Info-level messages are store in the device. And also shown in console when debuging but not in Release.
@param message_to_log nullable NSString message that helps to understand or gives more details about the log. If nil message,
 empty message information will be added on the log.
@return Nothing returned.
 */
#define LOG_INFO_WITH_MESSAGE(message_to_log)\
[[Logger share] infoWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Warn-level messages are intended for capturing information about things that might result a failure.
Warn-level messages are shown in console and  also store in the device.
@param error_to_log nullable NSError that helps to understand what went wrong. This is the actual error that we get from the
 app (if any). If nil error is pass, empty error information will be added on the log.
@return Nothing returned.
*/
#define LOG_WARN_WITH_ERROR(error_to_log)\
[[Logger share] warnWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Warn-level messages are intended for capturing information about things that might result a failure.
Warn-level messages are shown in console and  also store in the device.
@param message_to_log nullable NSString message that helps to understand or gives more details about the log. If nil message,
 empty message information will be added on the log.
@return Nothing returned.
 */
#define LOG_WARN_WITH_MESSAGE(message_to_log)\
[[Logger share] warnWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
Error-level messages are intended for reporting process-level errors. But not critical errors that lead to unknown states of the app.
Error-level messages are always store in the device and shown in console. And will NOT crash the app, just log the error.
@param error_to_log nullable NSError that helps to understand what went wrong. This is the actual error that we get from the
 app (if any). If nil error is pass, empty error information will be added on the log.
@return Nothing returned.
*/
#define LOG_ERROR_WITH_ERROR(error_to_log)\
[[Logger share] errorWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
Error-level messages are intended for reporting process-level errors. But not critical errors that lead to unknown states of the app.
Error-level messages are always store in the device and shown in console. And will NOT crash the app, just log the error.
@param message_to_log nullable NSString message that helps to understand or gives more details about the log. If nil message,
 empty message information will be added on the log.
@return Nothing returned.
 */
#define LOG_ERROR_WITH_MESSAGE(message_to_log)\
[[Logger share] errorWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\

/**
ErrorAndCrash-level messages are intended for reporting system-level or multi-process errors. Errors that should never happen
or that may lead to unknown states of the app.
ErrorAndCrash-level messages are always store in the device and shown in console. But also will crash the app when debug
but not in Release
@param error_to_log nullable NSError that helps to understand what went wrong. This is the actual error that we get from the
 app (if any). If nil error is pass, empty error information will be added on the log.
@return Nothing returned.
*/
#define LOG_ERROR_AND_CRASH_WITH_ERROR(error_to_log)\
[[Logger share] errorAndCrashWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                error:error_to_log];\

/**
ErrorAndCrash-level messages are intended for reporting system-level or multi-process errors. Errors that should never happen
or that may lead to unknown states of the app.
ErrorAndCrash-level messages are always store in the device and shown in console. But also will crash the app when debug
but not in Release
@param message_to_log nullable NSString message that helps to understand or gives more details about the log. If nil message,
 empty message information will be added on the log.
@return Nothing returned.
 */
#define LOG_ERROR_AND_CRASH_WITH_MESSAGE(message_to_log)\
[[Logger share] errorAndCrashWithFile:[NSString stringWithUTF8String:__FILE__]\
                line:__LINE__\
                function:[NSString stringWithUTF8String:__PRETTY_FUNCTION__]\
                message:message_to_log];\
