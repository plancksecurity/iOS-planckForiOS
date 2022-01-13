//
//  CalendarEventEditDelegate.swift
//  pEp
//
//  Created by Martín Brude on 7/12/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

protocol CalendarEventEditDelegate: AnyObject {

    /// Handle the Event has been added to the calendar.
    ///
    /// - Parameters:
    ///   - icsEvent: The ICS event that has been added
    ///   - attachment: The attachment that contains the ics event
    ///   - completion: The completion block
    func handleDidAddEvent(icsEvent: ICSEvent, attachment: Attachment, completion: (() -> Void)?)
}
