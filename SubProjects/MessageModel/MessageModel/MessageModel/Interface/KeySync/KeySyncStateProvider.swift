//
//  KeySyncStateProvider.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

/// Provides pEp Sync [en|dis]abled state and state changes.
public protocol KeySyncStateProvider: AnyObject {
    typealias NewState = Bool
    /// Closure called in case the pEp Sync [en|dis]abled state changed.
    var stateChangeHandler: ((NewState)->Void)? { get set }
    var isKeySyncEnabled: Bool { get }
}
