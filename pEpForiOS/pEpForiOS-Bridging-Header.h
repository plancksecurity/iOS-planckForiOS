//
//  pEpForiOS-Bridging-Header.h
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 12/04/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

#ifndef pEpForiOS_Bridging_Header_h
#define pEpForiOS_Bridging_Header_h

#pragma mark -- Core Data

#import "Models/machine/_Account.h"
#import "Models/machine/_Attachment.h"
#import "Models/machine/_Contact.h"
#import "Models/machine/_Folder.h"
#import "Models/machine/_Message.h"
#import "Models/machine/_MessageReference.h"

#pragma mark -- Pantomime headers

#import "Pantomime/CWConstants.h"
#import "Pantomime/CWFolder.h"
#import "Pantomime/CWService.h"
#import "Pantomime/CWConnection.h"
#import "Pantomime/CWTCPConnection.h"
#import "Pantomime/CWIMAPFolder.h"
#import "Pantomime/CWCacheRecord.h"

#import "Pantomime/CWCacheManager.h"
#import "Pantomime/CWIMAPCacheManager.h"

#import "Pantomime/CWIMAPStore.h"
#import "Pantomime/CWIMAPMessage.h"
#import "Pantomime/CWMessage.h"
#import "Pantomime/CWFlags.h"

#import "Pantomime/CWSMTP.h"
#import "Pantomime/CWInternetAddress.h"
#import "Pantomime/NSData+Extensions.h"

#import "Pantomime/CWMIMEMultipart.h"
#import "Pantomime/CWMIMEUtility.h"

#pragma mark -- pEp Headers

#import "pEpiOSAdapter/PEPiOSAdapter.h"
#import "pEpiOSAdapter/PEPSession.h"
#import "message_api.h"

#pragma mark -- Misc

#import "TFHpple.h"
#import "PureLayout.h"
#import "KeyboardObserver.h"

#endif /* pEpForiOS_Bridging_Header_h */
