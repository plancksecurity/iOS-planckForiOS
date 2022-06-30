//
//  EventsTrackingUtil.swift
//  pEpIOSToolbox
//
//  Created by Martín Brude on 30/6/22.
//  Copyright © 2022 pEp Security SA. All rights reserved.
//

import Foundation
import Amplitude
import pEpIOSToolbox

protocol EventTrackingUtilProtocol {

    /// Initial setup
    func setup()

    /// Tracks an event. Events are saved locally.
    /// Settings may prevent any event log.
    /// Uploads are batched to occur every 30 events or every 30 seconds (whichever comes first), as well as on app close.
    /// - Parameters:
    ///   - eventType: The name of the event you wish to track.
    ///   - eventProperties: You can attach additional data to any event by passing a Dictionary object with property: value pairs.
    func logEvent(_ eventType: String, withEventProperties eventProperties: [AnyHashable : Any]?)
}

/// Class to handle the event tracking
class EventTrackingUtil: EventTrackingUtilProtocol {

    /// The shared instance
    public static let shared = EventTrackingUtil()
    private let amplitudeKey = "AMPLITUDE_API_KEY"

    private init() { }

    public func setup() {
        guard let settings = Bundle.main.infoDictionary,
              let amplitudeApiKey = settings[amplitudeKey] as? String else {
            Log.shared.errorAndCrash(message: "Amplitude Api Key not found")
            return
        }

        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(amplitudeApiKey)//, userId: UUID().uuidString)
        Amplitude.instance().setUserId(UUID().uuidString)
        Amplitude.instance().minTimeBetweenSessionsMillis = 10 * 60 * 1000 // 10 minutes
        Amplitude.instance().setServerZone(AMPServerZone.EU)
    }

    public func logEvent(_ eventType: String, withEventProperties eventProperties: [AnyHashable : Any]?) {
        guard AppSettings.shared.shouldTrackEvents else {
            // We must not track events, nothing to do.
            return
        }
        Amplitude.instance().logEvent(eventType, withEventProperties: eventProperties)
    }
}
