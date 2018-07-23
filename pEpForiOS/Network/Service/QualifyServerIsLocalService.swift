//
//  QualifyServerIsLocalService.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

class QualifyServerIsLocalService: QualifyServerIsLocalServiceProtocol {
    let opQueue = OperationQueue()

    weak var delegate: QualifyServerIsLocalServiceDelegate?

    func qualify(serverName: String) {
        let op = QualifyServerIsLocalOperation(serverName: serverName)
        op.completionBlock = { [weak self] in //Looks like leak to me. Tripple check, make op weak.
            self?.delegate?.didQualify(serverName: serverName,
                                       isLocal: op.isLocal,
                                       error: op.error)
        }
        opQueue.addOperation(op)
    }
}
