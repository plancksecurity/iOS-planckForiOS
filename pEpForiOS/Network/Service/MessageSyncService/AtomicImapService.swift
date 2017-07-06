//
//  AtomicImapService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

typealias ServiceFinishedHandler = (_ error: Error?) -> ()

class AtomicImapService: ServiceErrorProtocol {
    private(set) public var error: Error?

    let backgroundQueue = OperationQueue()

    let parentName: String?
    let backgrounder: BackgroundTaskProtocol?
    
    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil) {
        self.parentName = parentName
        self.backgrounder = backgrounder
    }

    func handle(error: Error, taskID: BackgroundTaskID?, handler: ServiceFinishedHandler?) {
        backgrounder?.endBackgroundTask(taskID)
        handler?(error)
    }

    // MARK - ServiceErrorProtocol

    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}
