//
//  QualifyServerIsLocalService.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

//!!!: move to interface
public class QualifyServerIsLocalService: QualifyServerIsLocalServiceProtocol {
    private let opQueue = OperationQueue()

    public weak var delegate: QualifyServerIsLocalServiceDelegate?

    public func qualify(serverName: String) {
        let op = QualifyServerIsLocalOperation(serverName: serverName)
        op.completionBlock = { [weak self] in //Looks like leak to me. Tripple check, make op weak.
            self?.delegate?.didQualify(serverName: serverName,
                                       isLocal: op.isLocal,
                                       error: op.error)
        }
        opQueue.addOperation(op)
    }

    /**
     Make it accessible from the outside.
     */
    public init() {}
}
