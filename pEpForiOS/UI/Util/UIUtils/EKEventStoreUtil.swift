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

    /// Add an event to the calendar
    /// - Parameters:
    ///   - event: The Event to add
    ///   - completion: The completion callabck
    func addEvent(event: EKEvent, completion: @escaping EKEventStoreUtil.EventsCalendarManagerResponse)

    /// Remove an event from the calendar
    ///
    /// - Parameters:
    ///   - event: The event to remove
    ///   - completion: The completion callback
    func removeEvent(event: EKEvent, completion: @escaping EKEventStoreUtil.EventsCalendarManagerResponse)

    /// Retrieve an EKEvent generated from ICSEvent
    /// - Parameter event: The EKEvent
    func convert(event: ICSEvent) -> EKEvent

    /// Indicates if an event already exists
    /// - Parameter eventToCheck: The event to check
    func eventAlreadyExists(eventToCheck: EKEvent) -> Bool
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

    /// Adds the event to the calendar, if possible.
    /// This might fail when saving the event or the event may be already added to the calendar.
    ///
    /// - Parameters:
    ///   - event: The event to add.
    ///   - completion: The callback to be executed once the event is added or not.
    public func addEvent(event: EKEvent, completion: @escaping EventsCalendarManagerResponse) {
        if !eventAlreadyExists(eventToCheck: event) {
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                // Error while trying to create event in calendar
                completion(.failure(.eventNotAddedToCalendar))
            }
            completion(.success(true))
        } else {
            completion(.failure(.eventAlreadyExistsInCalendar))
        }
    }

    /// Remove an event from the calendar, if possible.
    /// This might fail when removing or the event may not exist in the calendar-
    ///
    /// - Parameters:
    ///   - event: The event to remove
    ///   - completion: The callback to be executed once the event is removed or not.
    public func removeEvent(event: EKEvent, completion: @escaping EventsCalendarManagerResponse) {
        if eventAlreadyExists(eventToCheck: event) {

            let predicate = eventStore.predicateForEvents(withStart: event.startDate, end: event.endDate, calendars: nil)
            let events = eventStore.events(matching: predicate)

            events.forEach { ev in
                do {
                    try eventStore.remove(ev, span: .thisEvent)
                } catch {
                    // Error while trying to delete event from calendar
                    completion(.failure(.cantDeleteEvent))
                }
            }
            completion(.success(true))
        } else {
            completion(.failure(.eventDoesNotExist))
        }
    }

    /// Indicates if the event already exists in the calendar.
    /// - Parameter eventToCheck: The event to check
    /// - Returns: True if it already exists in the calendar.
    public func eventAlreadyExists(eventToCheck: EKEvent) -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: eventToCheck.startDate, end: eventToCheck.endDate, calendars: nil)
        let existingEvents = eventStore.events(matching: predicate)
        let eventAlreadyExists = existingEvents.contains { (event) -> Bool in
            return eventToCheck.title == event.title && event.startDate == eventToCheck.startDate && event.endDate == eventToCheck.endDate
        }
        return eventAlreadyExists
    }

    /// Convert ICSEvent to EKEvent
    ///
    /// - Parameter event: The event to convert
    /// - Returns: The EK Event already configured.
    public func convert(event: ICSEvent) -> EKEvent {
        return parser.getEkEvent(from: event, store: eventStore)
    }
}
