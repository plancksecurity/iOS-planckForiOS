//
//  UIUtils+CalendarEvents.swift
//  pEp
//
//  Created by Martín Brude on 21/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

import EventKit
import EventKitUI

//MARK: - Edit

extension UIUtils {

    public static func presentEditEventCalendarView(event: ICSEvent,
                                                    eventEditViewDelegate: EKEventEditViewDelegate,
                                                    eventDetailPresentationCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse,
                                                    removeEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse,
                                                    addEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse) {
        let authStatus = eventStoreUtil.getAuthorizationStatus()
        switch authStatus {
        case .authorized:
            eventDetailPresentationCallback(.success(true))
            presentEditEventCalendarDetailModal(event: event, editViewDelegate: eventEditViewDelegate, removeEventCallback: removeEventCallback, addEventCallback: addEventCallback)
        case .notDetermined:
            // Auth is not determined
            // We request access to the calendar
            eventStoreUtil.requestAccess { (accessGranted, error) in
                if accessGranted {
                    presentEditEventCalendarDetailModal(event: event, editViewDelegate: eventEditViewDelegate, removeEventCallback: removeEventCallback, addEventCallback: addEventCallback)
                    eventDetailPresentationCallback(.success(true))
                } else {
                    eventDetailPresentationCallback(.failure(.calendarAccessDeniedOrRestricted))
                }
            }
        case .denied, .restricted:
            // Auth denied or restricted, we should display a popup
            eventDetailPresentationCallback(.failure(.calendarAccessDeniedOrRestricted))
        @unknown default:
            Log.shared.errorAndCrash(message: "AuthStatus case not supported")
        }
    }
}

//MARK: - Private

extension UIUtils {

    private static func presentEditEventCalendarDetailModal(event: ICSEvent,
                                                            editViewDelegate: EKEventEditViewDelegate,
                                                            removeEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse,
                                                            addEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse) {
        DispatchQueue.main.async {
            let ekEvent = eventStoreUtil.convert(event: event)
            let ekEditEventViewController = getEkEditEventViewController(ekEvent: ekEvent, editViewDelegate: editViewDelegate, eventStore: eventStoreUtil.eventStore)
            UIApplication.currentlyVisibleViewController().present(ekEditEventViewController, animated: true, completion: nil)
        }
    }

    private static func getEkEditEventViewController(ekEvent: EKEvent, editViewDelegate: EKEventEditViewDelegate, eventStore: EKEventStore) -> EKEventEditViewController {
        let eventViewController = EKEventEditViewController()
        eventViewController.editViewDelegate = editViewDelegate
        eventViewController.eventStore = eventStore
        eventViewController.event = ekEvent
        eventViewController.title = ekEvent.title
        return eventViewController
    }
}
