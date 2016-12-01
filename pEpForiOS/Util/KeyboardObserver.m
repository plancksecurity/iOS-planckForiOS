//
//  KeyboardObserver.m
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/03/16.
//  Copyright © 2016 pEp Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KeyboardObserver.h"

@interface KeyboardObserver ()

@end

@implementation KeyboardObserver

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

}

- (void)unregisterKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name: UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name: UIKeyboardWillHideNotification object:nil];
}

/**
 Called when the UIKeyboardDidShowNotification is sent.
 */
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
    }
}

/**
 Called when the UIKeyboardWillHideNotification is sent.
 */
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

@end
