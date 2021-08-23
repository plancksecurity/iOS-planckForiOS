//
//  CalendarEventBannerViewModel.swift
//  pEp
//
//  Created by Martín Brude on 14/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

import EventKit
import EventKitUI

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

    //MARK: - UI

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

    //MARK: - User Input

    /// Handle the view button was tapped
    public func handleViewButtonTapped(event: ICSEvent) {
        presentEditEventCalendarView(event: event)
    }

    /// Handle the close button was tapped
    public func handleCloseButtonTapped() {
        delegate?.dismiss()
    }
}

//MARK: - EKEventEditViewDelegate

extension CalendarEventsBannerViewModel: EKEventEditViewDelegate {
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}

//MARK: - EKEventViewDelegate

extension CalendarEventsBannerViewModel: EKEventViewDelegate {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        controller.dismiss(animated: true, completion: nil)
    }
}

//MARK: - Private

extension CalendarEventsBannerViewModel {

    private func showErrorAlert(error: EKEventStoreUtil.CalendarError) {
        UIUtils.showTwoButtonAlert(withTitle:  NSLocalizedString("Error", comment: "Error title"),
                                   message: error.errorDescription,
                                   cancelButtonText: NSLocalizedString("Cancel", comment: "Cancel - button title"),
                                   positiveButtonText: NSLocalizedString("Settings", comment: "Settings - button title"),
                                   cancelButtonAction: { [weak self] in
                                    guard let me = self else {
                                        Log.shared.errorAndCrash("Lost myself")
                                        return
                                    }
                                    me.showSettings()
                                   }, positiveButtonAction: { })
    }

    private func showSettings() {
        UIUtils.openSystemSettings()
    }
}

//MARK: - Edit

extension CalendarEventsBannerViewModel {
    private func presentEditEventCalendarView(event: ICSEvent) {
        UIUtils.presentEditEventCalendarView(event: event, eventEditViewDelegate: self) { [weak self] eventDetailPresentationResult in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            switch eventDetailPresentationResult {
            case .success:
                Log.shared.info("The calendar view was succesfully presented. Nothing to do")
            case .failure(let error):
                me.showErrorAlert(error: error)
            }
        } removeEventCallback:{ [weak self] removeEventResult in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            switch removeEventResult {
            case .success:
                Log.shared.info("An Event was succesfully removed. Nothing to do")
            case .failure(let error):
                me.showErrorAlert(error: error)
            }
        } addEventCallback: { [weak self] addEventResult in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            switch addEventResult {
            case .success:
                Log.shared.info("An Event was successfully added. Nothing to do")
            case .failure(let error):
                me.showErrorAlert(error: error)
            }
        }
    }

}
