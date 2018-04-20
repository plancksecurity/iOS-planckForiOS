//
//  QualifyServerIsLocalServiceProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 20.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

public protocol QualifyServerIsLocalServiceDelegate: class {
    func didQualify(serverName: String, isLocal: Bool)
}

public protocol QualifyServerIsLocalServiceProtocol {
    var delegate: QualifyServerIsLocalServiceDelegate? { get set }

    func qualify(serverName: String)
}
