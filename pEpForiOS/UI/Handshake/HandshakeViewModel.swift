//
//  HandshakeViewModel.swift
//  pEp
//
//  Created by Martin Brude on 30/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

/// View Model to handle the handshake views.
final class HandshakeViewModel {
    
    /// The identities to handshake
    private var identities : [Identity]
    private var partner : PEPIdentity
    
    /// The status of the privacy with a partner.
    enum PrivacyStatus {
        case Secure
        case SecureAndTrusted
        case Unsecure
    }
    
    /// The item that represents the handshake partner
    struct HandshakeItem {
        /// Indicates the handshake partner's name
        var from: String
        /// The current language
        var currentLanguage: String
        /// Rrepesents the partner image to display
        var identityImageTool: IdentityImageTool
        /// The privacy status in between the current user and the partner
        var privacyStatus: PrivacyStatus
        /// The trustwords to validate
        var trustwords: [String]?
        /// Indicates if the trustwords are long
        var longTrustwords: Bool
    }
    
    /// Items to be displayed in the View Controller
    private (set) var items: [HandshakeItem] = [HandshakeItem]()
    
    /// Number of elements in items
    var count: Int {
        get {
            return items.count
        }
    }

    /// Constructor
    /// - Parameters:
    ///   - identities: The identities to handshake
    ///   - partner: The concret partner to handshake
    init(identities : [Identity], partner : PEPIdentity) {
        self.identities = identities
        self.partner = partner
    }
    
    ///Access method to get the rows
    func rows(for index: Int) -> HandshakeItem {
        return items[index]
    }
    
    /// Provides the description for the row accordint to the privacy status of the item.
    /// - Parameter privacyStatus: The privacy status of the handshake partner.
    func description(for privacyStatus: PrivacyStatus) -> String {
        return ""
    }
    
    /// Provides the name of the the privacy status of the item.
    /// - Parameter privacyStatus: The privacy status of the handshake partner
    func privacyStatusName(for privacyStatus: PrivacyStatus) -> String {
        return ""
    }
    
    /// Returns the trustwords for the item.
    /// - Parameter item: The handshake partner item
    func trustwords(for item: HandshakeItem) -> String? {
        return determineTrustwords(item: item, identitySelf: selfIdentity, identityPartner: partner)
    }

    ///MARK: - Private
    
    /// This method determines and returns the trustwords, when possible.
    ///
    /// - Parameters:
    ///   - item: The handshake partner item
    ///   - identitySelf: The ´identity´ of the current user
    ///   - identityPartner: The ´identity´ of the user to get the handshake
    /// - Returns: The trustwords to make the handshake
    private func determineTrustwords(item: HandshakeItem,
                                     identitySelf: PEPIdentity,
                                     identityPartner: PEPIdentity) -> String? {
        do {
            return try PEPSession().getTrustwordsIdentity1(identitySelf,
                                                           identity2: identityPartner,
                                                           language: item.currentLanguage,
                                                           full: item.longTrustwords)
        } catch let err as NSError {
            Log.shared.error("%@", "\(err)")
            return nil
        }
    }
    
    private var selfIdentity : PEPIdentity {
        get {
            //TODO: GET self identity
            return PEPIdentity()
        }
    }
}
