//
//  EmailDisplayReadStatusManager.swift
//  pEp
//
//  Created by Andreas Buff on 02.02.21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

/// For several (technical and UX) reasons mails should not be imediatelly set as SEEN when
/// displaying it to the user but only after a certain time.
///
/// This util handles it for you.
///
/// HowTo:
/// * You MUST call `startedDisplaying` and `stoppedDisplaying` for all messges
/// THis util then handles the rest for you.
protocol EmailDisplayReadStatusManagerProtocol {
    /// Call this when starting to display a message to the user.
    func startedDisplaying(message: Message)
    /// Call this when stopping to display a message to the user.
    func stoppedDisplaying(message: Message)
}

class EmailDisplayReadStatusManager {
    private let minReadTime: TimeInterval = 0.5
    private typealias StartDisplayTime = Date
    private var timePerMessageCache = [Message:StartDisplayTime]()
}

// MARK: - EmailDisplayTimeCounterProtocol

extension EmailDisplayReadStatusManager: EmailDisplayReadStatusManagerProtocol {

    func startedDisplaying(message: Message) {
        timePerMessageCache[message] = Date()
    }
    func stoppedDisplaying(message: Message) {
        guard let cachedMsgDisplayTime = timePerMessageCache[message] else {
            Log.shared.info("Stopped displaying a message that was never reproted as displaying. Seems tobe a valid case. Looks like CollectionViewDelegate doesnot call willDisForItemAtIndexPath consistantly")
            return
        }
        let now = Date()
        if now.timeIntervalSince(cachedMsgDisplayTime) > minReadTime {
            message.markAsSeen()
        }
    }
}
