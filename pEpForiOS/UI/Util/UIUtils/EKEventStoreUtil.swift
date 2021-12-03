//
//  EKEventStoreUtil.swift
//  pEpForiOS
//
//  Created by Martín Brude on 13/7/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import EventKit

protocol EKEventStoreUtilProtocol {

    /// Request access to the user's calendar
    /// - Parameter completion: The completion callback
    func requestAccess(completion: @escaping EKEventStoreRequestAccessCompletionHandler)

    /// Retrieve the authorization status for events.
    func getAuthorizationStatus() -> EKAuthorizationStatus

    /// Retrieve an EKEvent generated from ICSEvent
    /// - Parameter event: The EKEvent
    func convert(event: ICSEvent) -> EKEvent

    /// Indicates if an event already exists
    /// - Parameter eventToCheck: The event to check
    func eventAlreadyExists(eventToCheck: EKEvent) -> Bool

    /// Retrieves a EKEvent from an ICSEvent.
    /// If it is already added returns the same instance, otherwise converts the ICSEvent to a new EKEvent.
    ///
    /// - Parameter event:The ICS event
    func getEKEventFromICSEvent(event: ICSEvent)-> EKEvent
}

/// This util facilitates interactions with EKEventStore, for example to add or remove events.
class EKEventStoreUtil: NSObject, EKEventStoreUtilProtocol {

    enum CalendarError: LocalizedError {
        case calendarAccessDeniedOrRestricted
        case eventNotAddedToCalendar
        case eventAlreadyExistsInCalendar
        case cantDeleteEvent
        case eventDoesNotExist

        /// Calendar error description
        public var errorDescription: String? {
            switch self {
            case .calendarAccessDeniedOrRestricted:
                return NSLocalizedString("The calendar access was denied or restricted", comment: "Lack of permissions error message")
            case .cantDeleteEvent:
                return NSLocalizedString("The event can't be deleted", comment: "Can't delete the event")
            case .eventAlreadyExistsInCalendar:
                return NSLocalizedString("The event already exists in the calendar", comment: "Event already exists error message")
            case .eventNotAddedToCalendar:
                return NSLocalizedString("Was not possible to add the event to the calendar", comment: "Can't add event to calendar error message")
            case .eventDoesNotExist:
                return NSLocalizedString("The event does not exist in the calendar", comment: "Missing event error message")
            }
        }
    }

    public typealias EventsCalendarManagerResponse = (_ result: Result<Bool, CalendarError>) -> Void
    public private(set) var eventStore = EKEventStore()
    private final var parser: ICSParserProtocol

    /// Constructor
    /// - Parameter parser: The ICS files parser.
    init(parser: ICSParserProtocol = ICSParser()) {
        self.parser = parser
        super.init()
    }

    /// Users are able to grant or deny access to events.
    ///
    /// - Parameter completion: The callback to be executed when the user confirms or reject to give access to the events.
    public func requestAccess(completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        eventStore.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            completion(accessGranted, error)
        }
    }

    /// indicates the currently granted authorization status for the EKEntityType
    /// - Returns: The authorization status
    public func getAuthorizationStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: EKEntityType.event)
    }

    /// Indicates if the event already exists in the calendar.
    /// - Parameter eventToCheck: The event to check
    /// - Returns: True if it already exists in the calendar.
    public func eventAlreadyExists(eventToCheck: EKEvent) -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: eventToCheck.startDate, end: eventToCheck.endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)
        return existingEvents.contains { (event) -> Bool in
            return eventToCheck.title == event.title && event.startDate == eventToCheck.startDate && event.endDate == eventToCheck.endDate
        }
    }

    /// Convert ICSEvent to EKEvent
    ///
    /// - Parameter event: The event to convert
    /// - Returns: The EK Event already configured.
    public func convert(event: ICSEvent) -> EKEvent {
        return parser.getEkEvent(from: event, store: eventStore)
    }

    /// Retrieves a EKEvent from an ICSEvent.
    /// If it is already added returns the same instance, otherwise converts the ICSEvent to a new EKEvent.
    ///
    /// - Parameter event:The ICS event
    func getEKEventFromICSEvent(event: ICSEvent)-> EKEvent {
        guard let startDate = event.startDate, let endDate = event.endDate else {
            return convert(event: event)
        }
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)
        if let found = existingEvents.first(where: {$0.title == event.summary}) {
            return found
        }
        return convert(event: event)
    }
}
