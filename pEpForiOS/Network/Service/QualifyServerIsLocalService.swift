//
//  QualifyServerIsLocalService.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class QualifyServerIsLocalService: QualifyServerIsLocalServiceProtocol {
    enum QualifyServerIsLocalServiceError: Error {
        case notImplemented
    }

    weak var delegate: QualifyServerIsLocalServiceDelegate?

    func qualify(serverName: String) {
        delegate?.didQualify(serverName: serverName,
                             isLocal: nil,
                             error: QualifyServerIsLocalServiceError.notImplemented)
    }
}
