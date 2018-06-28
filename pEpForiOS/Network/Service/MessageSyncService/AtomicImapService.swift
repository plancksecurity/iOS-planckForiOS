//
//  AtomicImapService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

typealias ServiceFinishedHandler = (_ error: Error?) -> ()

protocol ServiceExecutionProtocol {
    func cancel()
    func execute(handler: ServiceFinishedHandler?)
}

class AtomicImapService: ServiceErrorProtocol {
    let backgroundQueue = OperationQueue()

    let parentName: String
    let backgrounder: BackgroundTaskProtocol?
    
    init(parentName: String = #function, backgrounder: BackgroundTaskProtocol? = nil) {
        self.parentName = parentName
        self.backgrounder = backgrounder
    }

    func handle(error: Error, taskID: BackgroundTaskID?, handler: ServiceFinishedHandler?) {
        backgrounder?.endBackgroundTask(taskID)
        handler?(error)
    }

    // MARK: - ServiceErrorProtocol

    private(set) public var error: Error?

    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}
