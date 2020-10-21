//
//  ExtraKey+TestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 21.10.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

@testable import MessageModel
import CoreData

// MARK: - ExtraKey+TestUtils

extension ExtraKey {

    public convenience init(withFpr fpr: String) {
        let moc: NSManagedObjectContext = Stack.shared.mainContext
        let cdCreatee = CdExtraKey(context: moc)
        cdCreatee.fingerprint = fpr
        self.init(cdObject: cdCreatee, context: moc)
    }
}
