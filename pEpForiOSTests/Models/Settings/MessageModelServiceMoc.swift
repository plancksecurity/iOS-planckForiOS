//
//  MessageModelServiceMoc.swift
//  pEpForiOSTests
//
//  Created by Alejandro Gelos on 19/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
@testable import MessageModel

final class MessageModelServiceMoc: MessageModelServiceProtocol {
    var enableKeySyncWasCalled = false
    var disableKeySyncWasCalled = false


    func start_old() throws {}

    func processAllUserActionsAndStop_old() {}

    func cancel_old(updateIdentities: Bool) {}

    func checkForNewMails_old(completionHandler: @escaping (Int?) -> ()) {}

    func enableKeySync() {
        enableKeySyncWasCalled = true
    }

    func disableKeySync() {
        disableKeySyncWasCalled = true
    }

    func start() { }

    func stop() { }

    func finish() { }
}
