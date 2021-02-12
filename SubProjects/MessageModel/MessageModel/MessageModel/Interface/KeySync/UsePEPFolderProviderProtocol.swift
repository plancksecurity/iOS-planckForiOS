//
//  UsePEPFolderProviderProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Someone who tells us whether or not to create a pEp folder for storing pEp sync messages (or
/// to store it in INBOX otherwize).
public protocol UsePEPFolderProviderProtocol {
    var usePepFolder: Bool { get }
}
