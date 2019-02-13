//
//  ServiceErrorProtocol.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 16/12/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 For exchanging errors between `BaseOperation`s.
 */
public protocol ServiceErrorProtocol {
    var error: Error? { get }
    func addError(_ error: Error)
    func hasErrors() -> Bool
}
