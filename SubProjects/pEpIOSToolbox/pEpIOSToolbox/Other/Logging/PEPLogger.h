//
//  PEPLogger.h
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 18.03.21.
//  Copyright © 2021 pEp Security SA. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PEPLogger : NSObject
+ (void)logInfoFilename:(const char *)filename
               function:(const char *)function
                   line:(NSInteger)line
                 message:(NSString *)message;

+ (void)logWarnFilename:(const char *)filename
               function:(const char *)function
                   line:(NSInteger)line
                message:(NSString *)message;

+ (void)logErrorFilename:(const char *)filename
                function:(const char *)function
                    line:(NSInteger)line
                 message:(NSString *)message;

@end

#define LogInfo(...) [PEPLogger logInfoFilename:__FILE__ function:__FUNCTION__ line:__LINE__ message:[NSString stringWithFormat:__VA_ARGS__]];
#define LogWarn(...) [PEPLogger logWarnFilename:__FILE__ function:__FUNCTION__ line:__LINE__ message:[NSString stringWithFormat:__VA_ARGS__]];
#define LogError(...) [PEPLogger logErrorFilename:__FILE__ function:__FUNCTION__ line:__LINE__ message:[NSString stringWithFormat:__VA_ARGS__]];

NS_ASSUME_NONNULL_END

