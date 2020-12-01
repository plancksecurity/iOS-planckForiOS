//
//  Folder+VirtualMailbox.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Folder {
    /// Whether or not the default destructive action is "archive" instead of "delete".
    public var defaultDestructiveActionIsArchive: Bool {
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            return defaultValue
        }
        return providerInfo.defaultDestructiveActionIsArchive(forFolder: self)
    }
}
