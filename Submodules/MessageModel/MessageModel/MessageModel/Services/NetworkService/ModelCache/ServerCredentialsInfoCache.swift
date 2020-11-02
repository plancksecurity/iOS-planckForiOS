//
//  ServerCredentialsInfoCache.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 09.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 Caches some information of a CdServerCredentials in order to enable operations
 access to data in a thread-safe way, and also without having to operate
 in a context.
 */
struct ServerCredentialsInfoCache: Hashable {
    let objectID: NSManagedObjectID
    let hash: Int
    let password: String?
    let clientCertificate: SecIdentity?

    init(cdServerCredentials: CdServerCredentials) {
        self.objectID = cdServerCredentials.objectID
        self.hash = cdServerCredentials.hash
        self.password = cdServerCredentials.password
        if let cdClientCertificate = cdServerCredentials.clientCertificate,
            let keychainUuid = cdClientCertificate.keychainUuid {
            self.clientCertificate = ClientCertificateUtil().loadIdentity(uuid: keychainUuid)
        } else {
            self.clientCertificate = nil
        }
    }

    static func ==(l: ServerCredentialsInfoCache, r: ServerCredentialsInfoCache) -> Bool {
        return l.objectID == r.objectID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
