//
//  RetainChecker.m
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

#import "RetainChecker.h"

#import <FBRetainCycleDetector/FBRetainCycleDetector.h>

@implementation RetainChecker

/**
 Using the FBRetainCycleDetector in Swift crashes the compiler, so do it in ObjC.
 */
+ (void)runCheckerOnElements:(NSArray * _Nonnull)elements
{
    FBRetainCycleDetector *detector = [FBRetainCycleDetector new];
    for (id element in elements) {
        [detector addCandidate:element];
    }
    NSSet *retainCycles = [detector findRetainCycles];
    NSLog(@"%@", retainCycles);
}

@end
