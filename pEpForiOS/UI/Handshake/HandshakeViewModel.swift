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

/// Handshake View Mode Delegate
protocol HandshakeViewModelDelegate: class {
    /// Delegate method to notify that shake's action has been performed
    func didEndShakeMotion()
    
    /// Delegate method to notify the handshake has been reseted
    /// - Parameter indexPath: The indexPath of the row where the handshake was reseted
    func didResetHandshake(forRowAt indexPath: IndexPath)
    
    /// Delegate method to notify the handshake has been confirmed
    /// - Parameter indexPath: The indexPath of the row where the handshake was confirmed
    func didConfirmHandshake(forRowAt indexPath: IndexPath)

    /// Delegate method to notify the handshake has been rejected
    /// - Parameter indexPath: The indexPath of the row where the handshake was rejected
    func didRejectHandshake(forRowAt indexPath: IndexPath)

    /// Delegate method to notify when the protection status has changed
    /// - Parameter status: enabled or disabled
    func didChangeProtectionStatus(to status : HandshakeViewModel.ProtectionStatus)
    
    /// Delegate method to notify when the user selects a language
    /// - Parameter indexPath: The indexPath of the row where the user changes the language
    func didSelectLanguage(forRowAt indexPath: IndexPath)

    /// Delegate method to notify when the user toogle the protection
    /// - Parameter indexPath: The indexPath of the row where the user toogles the protection
    func didToogleProtection(forRowAt indexPath: IndexPath)
}

/// View Model to handle the handshake views.
final class HandshakeViewModel {

    var selfIdentity : Identity
    var handshakeUtil : HandshakeUtilProtocol
    weak var handshakeViewModelDelegate : HandshakeViewModelDelegate?

    enum ProtectionStatus {
        case enabled
        case disabled
    }
    
    /// The identities to handshake
    private var identities : [Identity]

    /// The item that represents the handshake partner
    struct Row {
        
        /// Indicates the handshake partner's name
        var name: String {
            get {
                return identity.address
            }
            
        }
        /// The row image
        var image: UIImage {
            get {
                return UIImage()
            }
        }
        /// The description for the row
        var description: String {
            get {
                return NSLocalizedString("", comment: "")
            }
        }
        /// The privacy status name
        var privacyStatusName: String {
            get {
                return NSLocalizedString("", comment: "")
            }
        }
        /// The trustwords to do the handshake
        var trustwords: String? {
            get {
                return ""
            }
        }
        /// The current language
        var currentLanguage: String
        /// Indicates if the trustwords are long
        var longTrustwords: Bool = false
        /// The privacy status in between the current user and the partner
        var privacyStatus: String?
        /// The identity of the user to do the handshake
        fileprivate var identity: Identity
    }
    
    /// Items to be displayed in the View Controller
    private (set) var rows: [Row] = [Row]()

    /// Constructor
    /// - Parameters:
    ///   - identities: The identities to handshake
    public init(identities : [Identity], selfIdentity : Identity,
                delegate : HandshakeViewModelDelegate, handshakeUtil : HandshakeUtilProtocol) {
        self.identities = identities
        self.selfIdentity = selfIdentity
        self.handshakeViewModelDelegate =  delegate
        self.handshakeUtil = handshakeUtil
        generateRows()
    }

    ///MARK - Actions
    
    /// Reject the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
    public func handleRejectHandshakePressed(at indexPath: IndexPath) {
        let row = rows[indexPath.row]
        do {
            try handshakeUtil.denyTrust(for: row.identity)
        } catch {
            Log.shared.errorAndCrash("%@", error.localizedDescription)
        }
    }
    
    /// Confirm the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
    public func handleConfirmHandshakePressed(at indexPath: IndexPath) {
        let row = rows[indexPath.row]
        do {
            try handshakeUtil.confirmTrust(for: row.identity)
            handshakeViewModelDelegate?.didConfirmHandshake(forRowAt: indexPath)
        } catch {
            Log.shared.error("Can't reset Trust")
        }

    }
    
    /// Reset the handshake
    /// The privacy status will be unsecure.
    /// - Parameter indexPath: The indexPath of the item to get the user to reset the handshake
    public func handleResetPressed(at indexPath: IndexPath) {
        let row = rows[indexPath.row]
        do {
            try handshakeUtil.resetTrust(for: row.identity)
            handshakeViewModelDelegate?.didResetHandshake(forRowAt: indexPath)
        } catch {
            Log.shared.error("Can't reset Trust")
        }
    }
    
    /// Returns the list of languages available for that row.
    public func handleChangeLanguagePressed() -> [String] {
        guard let list = try? handshakeUtil.languagesList() else {
            return [String]()
        }
        return list
    }
    
    /// Updates the selected language for that row.
    /// - Parameters:
    ///   - indexPath: The index path of the row
    ///   - language: The chosen language
    public func didSelectLanguage(forRowAt indexPath: IndexPath, language: String) {
        rows[indexPath.row].currentLanguage = language
        handshakeViewModelDelegate?.didSelectLanguage(forRowAt: indexPath)
    }
    
    /// Toogle PeP protection status
    public func handleToggleProtectionPressed(forRowAt indexPath: IndexPath) {
        handshakeViewModelDelegate?.didToogleProtection(forRowAt: indexPath)
    }
    
    public func getImageName(forRowAt indexPath: IndexPath) -> String? {
        return nil
    }
    
    /// Generate the trustwords
    /// - Parameter long: Indicates if the trustwords MUST be long.
    public func generateTrustwords(indexPath: IndexPath, long : Bool = false) -> String? {
        return trustwords(for: indexPath)
    }
    
    /// Method that reverts the last action performed by the user
    /// After the execution of this method there won't be any action to un-do.
    public func shakeMotionDidEnd() {
        handshakeViewModelDelegate?.didEndShakeMotion()
    }

    ///MARK: - Private

    /// Method that generates the rows to be used by the VC
    private func generateRows() {
        
        identities.forEach { (identity) in
            let status = String.pEpRatingTranslation(pEpRating: identity.pEpRating())
            let item = Row(currentLanguage: identity.language ?? "en",
                           longTrustwords: false,
                           privacyStatus:status.title,
                           identity: identity)
            rows.append(item)
        }
    }
    
    /// Returns the trustwords for the item.
    /// - Parameter item: The handshake partner item
    private func trustwords(for indexPath: IndexPath, long : Bool = false) -> String? {
        let handshakeItem = rows[indexPath.row]
        do {
            return try handshakeUtil?.getTrustwords(forSelf: selfIdentity,
                                                    and: handshakeItem.identity,
                                                    language: handshakeItem.currentLanguage,
                                                    long: long)
        } catch {
            Log.shared.error("Can't get trustwords")
            return nil
        }
    }
}
