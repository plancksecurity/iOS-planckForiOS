//
//  KeyboardObserver.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/03/16.
//  Copyright © 2016 pEp Foundation. All rights reserved.
//

@interface KeyboardObserver : NSObject

@property (weak, nonatomic) UIView *view;
@property (weak, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *activeTextField;

- (void)registerForKeyboardNotifications;
- (void)unregisterKeyboardNotifications;

@end
