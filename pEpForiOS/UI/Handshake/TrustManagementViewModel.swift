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
protocol TrustManagementViewModelDelegate: class {
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
    
    /// Delegate method to notify when the user selects a language
    /// - Parameter indexPath: The indexPath of the row where the user changes the language
    func didSelectLanguage(forRowAt indexPath: IndexPath)
    
    /// Delegate method to notify when the user choose to show more trustwords
    /// - Parameter indexPath: The indexPath of the row where the user changes the language
    func didToogleLongTrustwords(forRowAt indexPath: IndexPath)
}

/// View Model to handle the handshake views.
final class TrustManagementViewModel {
    public weak var trustManagementViewModelDelegate : TrustManagementViewModelDelegate?
    public var pEpProtected : Bool {
        get {
            return message.pEpProtected
        }
    }
    
    var message: Message
    private var session: Session {
        return message.session
    }

    private var handshakeUtil : TrustManagementUtilProtocol?
    private let undoManager = UndoManager()
    
    /// The item that represents the handshake partner
    struct Row {
        /// Indicates the handshake partner's name
        var name: String {
            get {
                let name = handshakeCombination.partnerIdentity.userName
                let address = handshakeCombination.partnerIdentity.address
                return name ?? address
            }
        }
        /// The description for the row
        var description: String {
            get {
                return color.privacyStatusDescription
            }
        }
        /// The privacy status name
        var privacyStatusName: String {
            get {
                let rating = handshakeCombination.partnerIdentity.pEpRating()
                let translations = String.pEpRatingTranslation(pEpRating: rating)
                return translations.title
            }
        }
        /// The privacy status image
        var privacyStatusImage: UIImage? {
            get {
                if forceRed {
                    return PEPColor.red.statusIconForMessage(enabled: true, withText: false)
                } else {
                    return color.statusIconForMessage(enabled: true, withText: false)
                }
            }
        }
        /// The current language
        var currentLanguage: String
        /// Indicates if the trustwords are long
        var longTrustwords: Bool = false
        /// The privacy status in between the current user and the partner
        var privacyStatus: String?
        /// Status indicator
        var color : PEPColor {
            get {
                return handshakeCombination.partnerIdentity.pEpColor()
            }
        }
        fileprivate var forceRed: Bool = false
        /// The identity of the user to do the handshake
        fileprivate var handshakeCombination: HandshakeCombination
        
        fileprivate var fingerprint: String?
    }
    
    /// Items to be displayed in the View Controller
    private (set) var rows: [Row] = [Row]()

    /// Constructor
    /// - Parameters:
    ///   - identities: The identities to handshake
    public init(message : Message, handshakeUtil: TrustManagementUtilProtocol? = TrustManagementUtil()) {
        self.message = message
        self.handshakeUtil = handshakeUtil
        generateRows()
    }

    ///MARK - Actions
    
    /// Reject the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
    public func handleRejectHandshakePressed(at indexPath: IndexPath) {
        registerUndoAction(at: indexPath)
        let identity : Identity = rows[indexPath.row].handshakeCombination.partnerIdentity
        let fingerprints = handshakeUtil?.getFingerprints(for: identity)
        rows[indexPath.row].fingerprint = fingerprints
        rows[indexPath.row].forceRed = true
        handshakeUtil?.denyTrust(for: identity)
        reevaluateAndUpdate()
        trustManagementViewModelDelegate?.didRejectHandshake(forRowAt: indexPath)
        
    }
    
    /// Confirm the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
    public func handleConfirmHandshakePressed(at indexPath: IndexPath) {
        registerUndoAction(at: indexPath)
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        handshakeUtil?.confirmTrust(for: row.handshakeCombination.partnerIdentity)
        reevaluateAndUpdate()
        trustManagementViewModelDelegate?.didConfirmHandshake(forRowAt: indexPath)
    }
    
    /// Handles the undo action. If possible will undo the last undoable action performed
    /// - Parameter indexPath: The index path of the row from where the last action has been performed.
    @objc public func handleUndo(forRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        handshakeUtil?.undoMisstrustOrTrust(for: row.handshakeCombination.partnerIdentity,
                                            fingerprints: row.fingerprint)
        reevaluateAndUpdate()
    }

    /// Handles the undo
    /// - Parameter indexPath: The indexPath of the item to get the user to undo last action.
    public func handleResetPressed(forRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        handshakeUtil?.resetTrust(for: row.handshakeCombination.partnerIdentity)
        reevaluateAndUpdate()
        trustManagementViewModelDelegate?.didResetHandshake(forRowAt: indexPath)
    }
    
    /// Returns the list of languages available for that row.
    public func handleChangeLanguagePressed() -> [String] {
        guard let list = handshakeUtil?.languagesList() else {
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
        trustManagementViewModelDelegate?.didSelectLanguage(forRowAt: indexPath)
    }
    
    /// Toogle PeP protection status
    public func handleToggleProtectionPressed() {
        message.pEpProtected.toggle()
    }
    
    /// Toogle PeP protection status
    public func handleToggleLongTrustwords(forRowAt indexPath: IndexPath) {
        rows[indexPath.row].longTrustwords.toggle()
        trustManagementViewModelDelegate?.didToogleLongTrustwords(forRowAt: indexPath)
    }

    /// Generate the trustwords
    /// - Parameter long: Indicates if the trustwords MUST be long.
    public func generateTrustwords(forRowAt indexPath: IndexPath, long : Bool = false) -> String? {
        let handshakeItem = rows[indexPath.row]
        do {
            let selfIdentity = handshakeItem.handshakeCombination.ownIdentity
            let partnerIdentity = handshakeItem.handshakeCombination.partnerIdentity
            return try handshakeUtil?.getTrustwords(for: selfIdentity,
                                                   and: partnerIdentity,
                                                   language: handshakeItem.currentLanguage,
                                                   long: long)
        } catch {
            Log.shared.error("Can't get trustwords")
            return nil
        }
    }
    
    /// Method that reverts the last action performed by the user
    /// After the execution of this method there won't be any action to un-do.
    public func shakeMotionDidEnd() {
        if (undoManager.canUndo) {
            undoManager.undo()
            trustManagementViewModelDelegate?.didEndShakeMotion()
        }
    }

    ///MARK: - Private

    private func reevaluateAndUpdate() {
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.error("Lost myself - The message will not be reevaluated")
                return
            }
            RatingReEvaluator.reevaluate(message: me.message)
        }
    }
    
    /// Method that generates the rows to be used by the VC
    private func generateRows() {
        handshakeUtil?.handshakeCombinations(message: message).forEach { (combination) in
            //default language is english
            let language = combination.partnerIdentity.language ?? "en"
            let row = Row(currentLanguage: language,
                          longTrustwords: false,
                          handshakeCombination: combination)
            rows.append(row)
        }
    }

    /// Register the action to be undo
    /// - Parameter indexPath: The indexPath of the row which the action to undo.
    private func registerUndoAction(at indexPath: IndexPath) {
        undoManager.registerUndo(withTarget: self,
                                 selector: #selector(handleUndo(forRowAt:)),
                                 object: indexPath)
    }
}

/// Image Extension
extension TrustManagementViewModel {
    
    /// Method that returns the user image for the current indexPath throught the callback
    /// - Parameters:
    ///   - indexPath: The index path to get the user image
    ///   - complete: The callback with the image
    public func getImage(forRowAt indexPath: IndexPath, complete: @escaping (UIImage?) -> ()) {
        
        //Check if it's cached, use it if so.
        let handshakeItem = rows[indexPath.row]
        let partnerIdentity = handshakeItem.handshakeCombination.partnerIdentity
        let contactImageTool = IdentityImageTool()
        let key = IdentityImageTool.IdentityKey(identity: partnerIdentity)
        if let cachedContactImage = contactImageTool.cachedIdentityImage(for: key) {
            complete(cachedContactImage)
            return
        }
        
        //If can't find the image in the cache, creates it from the session.
        let session = Session()
        let safePartnerIdentity = partnerIdentity.safeForSession(session)
        DispatchQueue.global(qos: .userInteractive).async {
            session.performAndWait {
                if let contactImage = contactImageTool.identityImage(for:
                    IdentityImageTool.IdentityKey(identity: safePartnerIdentity)) {
                    complete(contactImage)
                }
            }
        }
    }
}
