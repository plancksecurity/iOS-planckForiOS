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

//MARK: - EKEventEditViewController

extension UIUtils {

    public static func presentEditEventCalendarView(event: ICSEvent,
                                                    eventEditViewDelegate: EKEventEditViewDelegate,
                                                    delegate: UINavigationControllerDelegate,
                                                    eventDetailPresentationCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse,
                                                    addEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse) {
        let eventStoreUtil = EKEventStoreUtil()
        let authStatus = eventStoreUtil.getAuthorizationStatus()
        switch authStatus {
        case .authorized:
            eventDetailPresentationCallback(.success(true))
            presentEditEventCalendarDetailModal(event: event, editViewDelegate: eventEditViewDelegate, delegate: delegate, addEventCallback: addEventCallback)
        case .notDetermined:
            // Auth is not determined
            // We request access to the calendar
            eventStoreUtil.requestAccess { (accessGranted, error) in
                if accessGranted {
                    presentEditEventCalendarDetailModal(event: event, editViewDelegate: eventEditViewDelegate, delegate: delegate, addEventCallback: addEventCallback)
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
                                                            delegate: UINavigationControllerDelegate,
                                                            addEventCallback: @escaping EKEventStoreUtil.EventsCalendarManagerResponse) {
        DispatchQueue.main.async {
            let eventStoreUtil = EKEventStoreUtil()
            let ekEvent = eventStoreUtil.getEKEventFromICSEvent(event: event)
            let ekEditEventViewController = getEkEditEventViewController(ekEvent: ekEvent, editViewDelegate: editViewDelegate, delegate: delegate, eventStore: eventStoreUtil.eventStore)
            UIApplication.currentlyVisibleViewController().present(ekEditEventViewController, animated: true, completion: nil)
        }
    }

    private static func getEkEditEventViewController(ekEvent: EKEvent, editViewDelegate: EKEventEditViewDelegate, delegate: UINavigationControllerDelegate, eventStore: EKEventStore) -> EKEventEditViewController {
        let eventViewController = EKEventEditViewController()
        eventViewController.editViewDelegate = editViewDelegate
        eventViewController.eventStore = eventStore
        eventViewController.delegate = delegate
        eventViewController.event = ekEvent
        eventViewController.title = ekEvent.title
        return eventViewController
    }
}
