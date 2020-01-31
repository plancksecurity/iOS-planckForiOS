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
protocol HandshakeViewModelDelegate {
    
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
}

/// Protocol for a handshake row
/// It includes all data needed to display a handshake row.
protocol HandshakeRowProtocol {
    /// Indicates the handshake partner's name
    var name: String { get }
    /// The current language
    var currentLanguage: String { get }
    /// The privacy status in between the current user and the partner
    var privacyStatus: String? { get }
    /// Indicates if the trustwords are long
    var longTrustwords: Bool { get }
    /// The row description
    var description : String  { get }
    /// The item trustwords
    var trustwords : String? { get }
    /// The row image
    var image : UIImage { get }
}

/// View Model to handle the handshake views.
final class HandshakeViewModel {
    
    enum ProtectionStatus {
        case enabled
        case disabled
    }
    
    /// The identities to handshake
    private var identities : [Identity]

    /// The item that represents the handshake partner
    private struct HandshakeRow: HandshakeRowProtocol {
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
        /// Indicates the handshake partner's name
        var name: String {
            get {
                return identity.address
            }
        }
        /// The current language
        var currentLanguage: String {
            get {
                return identity.language ?? "en"
            }
        }
        /// Indicates if the trustwords are long
        var longTrustwords: Bool = false
        /// The privacy status in between the current user and the partner
        var privacyStatus: String?
        /// The identity of the user to do the handshake
        private var identity: Identity
    }
    
    /// Items to be displayed in the View Controller
    private (set) var rows: [HandshakeRowProtocol] = [HandshakeRow]()

    /// Constructor
    /// - Parameters:
    ///   - identities: The identities to handshake
    public init(identities : [Identity]) {
        self.identities = identities
    }

    ///MARK - Providers

    ///Access method to get the rows
    public func row(for index: Int) -> HandshakeRowProtocol {
        return rows[index]
    }

    ///MARK - Actions
    
    /// Reject the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
    public func handleRejectHandshakePressed(at indexPath: IndexPath) {

    }
    
    /// Confirm the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
    public func handleConfirmHandshakePressed(at indexPath: IndexPath) {
        
    }
    
    /// Reset the handshake
    /// The privacy status will be unsecure.
    /// - Parameter indexPath: The indexPath of the item to get the user to reset the handshake
    public func handleResetPressed(at indexPath: IndexPath) {
        
    }
    
    /// Returns the list of languages available for that row.
    public func handleChangeLanguagePressed() -> [String] {
        return [String]()
    }
    
    /// Updates the selected language for that row.
    /// - Parameters:
    ///   - indexPath: The index path of the row
    ///   - language: The chosen language
    public func didSelectLanguage(forRowAt indexPath: IndexPath, language: String) {
        
    }
    
    /// Toogle PeP protection status
    public func handleToggleProtectionPressed() {
        
    }
    
    public func getImageName(forRowAt indexPath: IndexPath) -> String? {
        return nil
    }
    
    /// Generate the trustwords
    /// - Parameter long: Indicates if the trustwords MUST be long.
    public func generateTrustwords(long : Bool) -> String? {
        return nil
    }
    
    /// Method that reverts the last action performed by the user
    /// After the execution of this method there won't be any action to un-do.
    public func shakeMotionDidEnd() {
        
    }

    ///MARK: - Private

    /// Method that generates the rows to be used by the VC
    private func generateRows() {
        identities.forEach { (identity) in
            //TODO: fix up identityImageTool
            let identityImageTool = IdentityImageTool()
            let item = HandshakeRow(longTrustwords: true, privacyStatus: nil, identity: identity)
            rows.append(item)
        }
    }
    
    /// This method determines and returns the trustwords, when possible.
    ///
    /// - Parameters:
    ///   - item: The handshake partner item
    ///   - identitySelf: The ´identity´ of the current user
    ///   - identityPartner: The ´identity´ of the user to get the handshake
    /// - Returns: The trustwords to make the handshake
    private func determineTrustwords(item: HandshakeRow,
                                     identitySelf: PEPIdentity,
                                     identityPartner: PEPIdentity) -> String? {
        do {
            return try PEPSession().getTrustwordsIdentity1(identitySelf,
                                                           identity2: identityPartner,
                                                           language: item.currentLanguage,
                                                           full: item.longTrustwords)
        } catch {
            Log.shared.error("%@", "\(error)")
            return nil
        }
    }
        
    private var selfIdentity : PEPIdentity {
        get {
            //TODO: GET self identity
            return PEPIdentity()
        }
    }
    
    /// Returns the trustwords for the item.
    /// - Parameter item: The handshake partner item
    private func trustwords(for indexPath: IndexPath) -> String? {
        guard let handshakeItem = rows[indexPath.row] as? HandshakeRow else {
            Log.shared.errorAndCrash(message: "Item not found")
            return nil
        }
        
        let partner = handshakeItem.identity.pEpIdentity()
        
        return determineTrustwords(item: handshakeItem,
                                   identitySelf: selfIdentity,
                                   identityPartner: partner)
    }
}
