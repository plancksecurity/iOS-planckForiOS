//
//  ClientCertificate.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.02.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ClientCertificate: MessageModelObjectProtocol, ManagedObjectWrapperProtocol {

    // MARK: - ManagedObjectWrapperProtocol

    typealias T = CdClientCertificate
    let moc: NSManagedObjectContext
    let cdObject: T

    required init(cdObject: T, context: NSManagedObjectContext) {
        self.cdObject = cdObject
        self.moc = context
    }

    // MARK: - Public API

    /// User readable label. Is not unique.
    public var label: String? {
        return cdObject.label
    }

    /// Import date.
    public var date: Date? {
        return cdObject.importDate
    }

    public var uuid: String? {
        return cdObject.keychainUuid
    }
}

extension ClientCertificate: Equatable {
    public static func ==(lhs: ClientCertificate, rhs: ClientCertificate) -> Bool {
        return lhs.cdObject.keychainUuid == rhs.cdObject.keychainUuid
    }
}

extension ClientCertificate: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cdObject.keychainUuid)
    }
}

