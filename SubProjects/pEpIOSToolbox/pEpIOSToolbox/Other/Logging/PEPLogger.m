//
//  PEPLogger.m
//  pEpIOSToolbox
//
//  Created by Andreas Buff on 18.03.21.
//  Copyright © 2021 pEp Security SA. All rights reserved.
//

#import "PEPLogger.h"
#import <pEpIOSToolbox/pEpIOSToolbox-Swift.h>

@implementation PEPLogger


+ (void)logInfoFilename:(const char *)filename
               function:(const char *)function
                   line:(NSInteger)line
                message:(NSString *)message
{
    [[Log shared]
     logInfoWithMessage:message
     function:[NSString stringWithUTF8String:function]
     filePath:[NSString stringWithUTF8String:filename]
     fileLine:line];
}

+ (void)logWarnFilename:(const char *)filename
               function:(const char *)function
                   line:(NSInteger)line
                message:(NSString *)message
{
    [[Log shared]
     logWarnWithMessage:message
     function:[NSString stringWithUTF8String:function]
     filePath:[NSString stringWithUTF8String:filename]
     fileLine:line];
}

+ (void)logErrorFilename:(const char *)filename
                function:(const char *)function
                    line:(NSInteger)line
                 message:(NSString *)message
{
    [[Log shared]
     logErrorWithMessage:message
     function:[NSString stringWithUTF8String:function]
     filePath:[NSString stringWithUTF8String:filename]
     fileLine:line];
}

+ (void)logErrorAndCrashFilename:(const char *)filename
                function:(const char *)function
                    line:(NSInteger)line
                 message:(NSString *)message
{
    [[Log shared] logErrorAndCrashWithMessage:message
                                     function:[NSString stringWithUTF8String:function]
                                     filePath:[NSString stringWithUTF8String:filename]
                                     fileLine:line];
}

@end
