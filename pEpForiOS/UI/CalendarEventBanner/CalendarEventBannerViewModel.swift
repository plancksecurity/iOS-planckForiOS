//
//  CalendarEventBannerViewModel.swift
//  pEp
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel
import pEpIOSToolbox

protocol CalendarEventBannerViewModelDelegate: AnyObject {
    /// Dismiss the banner
    func dismiss()
}

/// View Model that handles everything related to the Events Banner.
/// This takes care of the parsing and prepares the data to be shown.
/// Decides if the banner has to be shown and reacts to the user input: presenting event detail view, dismiss the banner.
class CalendarEventsBannerViewModel: NSObject {

    /// Delegate to communicate to the View Controller
    public private(set) weak var delegate: CalendarEventBannerViewModelDelegate?

    public var events: [ICSEvent] = [ICSEvent]()
    private let parser: ICSParserProtocol?


    public func isAlreadyInCalendar(event: ICSEvent) -> Bool {
        let eventStoreUtil = EKEventStoreUtil()
        let ekEvent = eventStoreUtil.convert(event: event)
        return eventStoreUtil.eventAlreadyExists(eventToCheck: ekEvent)
    }

    /// Constructor
    /// - Parameter events: The events to show.
    init(attachments: [Attachment], parser: ICSParserProtocol? = ICSParser(), delegate: CalendarEventBannerViewModelDelegate) {
        self.delegate = delegate
        self.parser = parser
        var eventsToAdd: [ICSEvent] = [ICSEvent]()
        attachments.forEach { attachment in
            if let data = attachment.data, let parser = parser {
                let content = String(decoding: data, as: UTF8.self)
                eventsToAdd.append(contentsOf: parser.events(for: content))
            }
        }
        self.events.append(contentsOf: eventsToAdd)
        self.events = self.events.sorted(by: { ($0.startDate ?? Date.distantPast)?.compare($1.startDate ?? Date.distantPast) == .orderedDescending })
        guard self.events.count > 0 else {
            Log.shared.errorAndCrash("Missing attachments")
            return
        }
    }

    /// Indicates wheater or not the banner should be shown
    public var shouldShowEventsBanner: Bool {
        return numberOfEvents > 0
    }

    /// The day number. For example, 31.
    public var dayNumber: String {
        guard let event = events.first else {
            Log.shared.errorAndCrash("Event not found")
            return "-"
        }
        guard let day = event.startDate?.get(.day) else {
            return "-"
        }
        return String(day)
    }

    /// The day of the week. For example, 'Monday'
    public var dayOfTheWeekLabel: String {
        guard let event = events.first else {
            Log.shared.errorAndCrash("Event not found")
            return "-"
        }
        guard let weekday = event.startDate?.weekday else {
            return "-"
        }
        return weekday
    }

    /// The number of Events
    public var numberOfEvents: Int {
        return events.count
    }

    /// The banner title
    public var title: String {
        if numberOfEvents > 1 {
            let format = NSLocalizedString("%@ Events found", comment: "Calendar Event Banner title - plural")
            return String(format: format, "\(events.count)")
        }
        return NSLocalizedString("1 Event found", comment: "Calendar Event Banner title - singular")
    }

    /// Handle the close button was tapped
    public func handleCloseButtonTapped() {
        delegate?.dismiss()
    }
}
