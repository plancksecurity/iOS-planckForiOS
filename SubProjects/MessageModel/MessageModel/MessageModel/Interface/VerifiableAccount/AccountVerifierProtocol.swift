//
//  AccountVerifierProtocol.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation

/// Wrapper around `VerifiableAccount` with some additions and changes,
/// suitable for use in an MDM context.
///
/// Differences to `VerifiableAccount`:
///
/// * Simplified interface
/// * Uses a callback instead of a delegate.
/// * Saves the account after successful verification.
public protocol AccountVerifierProtocol {
    
}
