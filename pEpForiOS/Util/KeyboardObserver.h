//
//  KeyboardObserver.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/03/16.
//  Copyright © 2016 pEp Foundation. All rights reserved.
//

@interface KeyboardObserver : NSObject

@property (weak, nonatomic, nullable) UIView *view;
@property (weak, nonatomic, nullable) UIScrollView *scrollView;
@property (strong, nonatomic, nullable) UITextField *activeTextField;

/**
 Call this method somewhere in your view controller setup code.
 */
- (void)registerForKeyboardNotifications;

/**
 Call to unregister observers. You should do that when your VC disappears.
 */
- (void)unregisterKeyboardNotifications;

@end
