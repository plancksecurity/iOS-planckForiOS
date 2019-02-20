//
//  pEpForiOS-Bridging-Header.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

#ifndef pEpForiOS_Bridging_Header_h
#define pEpForiOS_Bridging_Header_h

#pragma mark - pEp Headers

#import "pEpObjCAdapter/PEPObjCAdapter.h"
#import "pEpObjCAdapter/PEPSessionProtocol.h"
#import "pEpObjCAdapter/PEPLanguage.h"
#import "pEpObjCAdapter/PEPLanguage.h"
#import "pEpObjCAdapter/NSDictionary+Extension.h"
#import "pEpObjCAdapter/NSDictionary+Debug.h"
#import <pEpObjCAdapterFramework/pEpObjCAdapterFramework.h>
#import "pEpObjCAdapter/PEPMessage.h"
#import "pEpObjCAdapter/PEPAttachment.h"

#pragma mark - pEp AccountSettings Headers

#import "AccountSettings.h"
#import "AccountSettingsServer.h"

#pragma mark - HTML/Markdown

#import "Axt.h"
#import "cmark.h"
#import "NSString+Markdown.h"

#pragma mark - AppAuth

#import "AppAuth/AppAuth.h"

#pragma mark - Apple System Log facility

#import <asl.h>

#endif /* pEpForiOS_Bridging_Header_h */
