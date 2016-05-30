//
//  RetainChecker.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RetainChecker : NSObject

+ (void)runCheckerOnElements:(NSArray * _Nonnull)elements;

@end
