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
Sends a message to the delegate, with a notification as parameter.

@param del The delegate to send the message to.
@param sel The selector to invoke on the delegate.
@param name The name of the notification.
@param obj The keypair (obj, value) will be the content of the notification info dictionary.
@param key The keypair (obj, value) will be the content of the notification info dictionary.
@return Nothing returned.
*/
#define LOGDEBUG(message) \
Logger\
if (del && [del respondsToSelector: sel]) \
{ \
  [del performSelector: sel \
       withObject: [NSNotification notificationWithName: name \
                   object: self \
                   userInfo: info]]; \
}
