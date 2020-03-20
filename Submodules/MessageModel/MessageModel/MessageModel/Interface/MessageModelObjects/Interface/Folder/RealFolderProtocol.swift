//
//  RealFolderProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 25.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

public protocol RealFolderProtocol: DisplayableFolderProtocol {

    /// the account the folder belongs to
    var account: Account { get }

    /// Saves the current date as lastLookAt.
    func updateLastLookAt()
}
