//
//  CdFolder+VirtualMailbox.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 25.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - VirtualMailbox

public extension CdFolder {
    /// We currently only take Gmail into account.
    private var supportedProviders: [ProviderSpecificInformationProtocol] {
        return [GmailSpecificInformation(), OutlookO365SpecificInformation()]
    }

    private var providerSpecificInfo: ProviderSpecificInformationProtocol? {
        for providerInfo in supportedProviders {
            if providerInfo.belongsToProvider(self) {
                return providerInfo
            }
        }
        return nil
    }

    /// If true, things will go wrong if you append messages to this folder.
    ///
    /// Appending a message anyway will cause unexpected behaviour. Depending on the provider
    /// and folder type:
    /// - Error returned from server
    /// - Duplicated messages (as the server handles append)
    /// - Possibly all kinds of undefined behavior
    var shouldNotAppendMessages: Bool {
        let defaultValue = false
        guard let providerInfo = providerSpecificInfo else {
            // There are no provider specific rules
            return defaultValue
        }
        return !providerInfo.isOkToAppendMessages(toFolder: self)
    }
}
