//
//  UserNotificationTool+pEp.swift
//  pEp
//
//  Created by Andreas Buff on 19.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// pEp 4 iOS specific Extensions
extension UserNotificationTool {

    static func postUserNotification(forNumNewMails numMails: Int) {
        if numMails ==  UIApplication.shared.applicationIconBadgeNumber {
            // The number of new mails did not increase since informing the user last time.
            // Do not bother her again.
            // This is working also if the user turned off batch counter in the Apple Settings
            return
        }
        let title: String
        if numMails == 1 {
            title = NSLocalizedString("New message received",
                                      comment:
                "Title for notification show on lock screen for *one* new mail")
        } else {
            title = String(format: NSLocalizedString("%1d new messages received",
                                                     comment:
                                                        "Title for notification show on lock screen for new mails"),
                           numMails)
        }
        let body = NSLocalizedString("Slide for more",
                                     comment:
                                        "Body for notifications show on lock screen for new mail(s)")
        post(title: title, body: body, batch: numMails)
    }
}
