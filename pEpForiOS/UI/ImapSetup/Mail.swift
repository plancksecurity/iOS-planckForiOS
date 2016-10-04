//
//  Mail.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

open class Mail {

    var senderName:String
    var subject:String
    var contentMail:String
    var hour:String

    init(senderName:String,subject:String,contentMail:String,hour:String) {
        self.senderName = senderName
        self.subject = subject
        self.contentMail = contentMail
        self.hour = hour
    }
    
}
