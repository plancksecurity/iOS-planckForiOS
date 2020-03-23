//
//  ExtraKeys+Utils.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData

// MARK: - ExtraKeys+Utils

extension ExtraKey {

    public enum ExtraKeysError: Error {
        case invalidFPR
    }

    /// All ExtraKeys in DB
    static public func extraKeys(in session: Session = Session.main) -> [ExtraKey] {
        return CdExtraKey.allExtraKeys(in: session.moc)
            .map { MessageModelObjectUtils.getExtraKey(fromCdExtraKey: $0) }
    }

    /// Stores a fingerprint used to identify an Extry Key
    /// Valid FPRexamples: 4ABE3AAF59AC32CFE4F86500A9411D176FF00E97
    ///
    /// - note: FPRs everything that is not alphanumeric is stripped from the FPR. After striping
    ///         the FPR must the  have min 64 bits to be considered as valid.
    ///
    /// - Parameter fpr: fingerprint to store
    /// - throws: ExtraKeysServiceError if FPR is considered invalid
    public static func store(fpr: String, in session: Session = Session.main) throws {
        let moc = session.moc
        guard let fpr = fpr.toValidFpr else {
            throw(ExtraKeysError.invalidFPR)
        }
        let p = CdExtraKey.PredicateFactory.containing(fingerprinnt: fpr)
        let existing = CdExtraKey.all(predicate: p, in: moc)?.first
        if existing == nil {
            let createe = CdExtraKey(context: moc)
            createe.fingerprint = fpr
            moc.saveAndLogErrors()
        }
    }
}
