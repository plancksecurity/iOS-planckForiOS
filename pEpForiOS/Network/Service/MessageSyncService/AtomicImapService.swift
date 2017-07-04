//
//  AtomicImapService.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class AtomicImapService {
    public var error: Error?

    let backgroundQueue = OperationQueue()

    let parentName: String?
    let backgrounder: BackgroundTaskProtocol?
    
    init(parentName: String? = nil, backgrounder: BackgroundTaskProtocol? = nil) {
        self.parentName = parentName
        self.backgrounder = backgrounder
    }   
}

extension AtomicImapService: ServiceErrorProtocol {
    public func addError(_ error: Error) {
        if self.error == nil {
            self.error = error
        }
    }

    public func hasErrors() -> Bool {
        return error != nil
    }
}
