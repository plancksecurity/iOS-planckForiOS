//
//  MailList.swift
//  pEpForiOS
//
//  Created by ana on 18/4/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class MailList {

    var listOfMails = [Mail]()

    init() {

        let sendername1 = "Paquito Chocolatero"
        let sendername2 = "Antonio Machado"
        let sendername3 = "Lola Flores"

        let subject1 = "Invitacion para quedar"
        let subject2 = "Esto es un ejemplo de subjecct un poquito mas largo"
        let subject3 = "Te han hablado en Facebook"

        let hour1 = "9:00"
        let hour2 = "14:30"
        let hour3 = "2:00"

        let contentMail = "Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut     et dolore magna aliqua."

        let mail1 = Mail(senderName: sendername1, subject: subject1, contentMail: contentMail, hour: hour1)
        let mail2 = Mail(senderName: sendername2, subject: subject2, contentMail: contentMail, hour: hour2)
        let mail3 = Mail(senderName: sendername3, subject: subject3, contentMail: contentMail, hour: hour3)

        self.listOfMails.append(mail1)
        self.listOfMails.append(mail2)
        self.listOfMails.append(mail3)
        
    }
    
}