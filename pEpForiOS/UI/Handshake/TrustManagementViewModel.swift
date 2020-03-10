//
//  TrustManagementViewModel.swift
//  pEp
//
//  Created by Martin Brude on 30/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import PEPObjCAdapterFramework

/// TrustManagementViewModel View Mode Delegate
protocol TrustManagementViewModelDelegate: class {
    /// Delegate method to notify that an action ends and the view must be reloaded.
    func reload()
}

protocol TrustmanagementProtectionStateChangeDelegate: class {
    /// Called whenever the user toggles protection state (for the message)
    func protectionStateChanged(to newValue: Bool)
}

extension TrustManagementViewModel {
    /// The item that represents the handshake partner
    public struct Row {
        /// Indicates the handshake partner's name
        var name: String {
            let name = handshakeCombination.partnerIdentity.userName
            let address = handshakeCombination.partnerIdentity.address
            return name ?? address
        }
        /// The description for the row
        var description: String {
            if forceRed {
                return PEPColor.red.privacyStatusDescription
            }
            return color.privacyStatusDescription
        }
        /// The privacy status name
        var privacyStatusName: String {
            if (forceRed) {
                return String.trustIdentityTranslation(pEpRating: .underAttack).title
            }
            let rating = handshakeCombination.partnerIdentity.pEpRating()
            let translations = String.trustIdentityTranslation(pEpRating: rating)
            return translations.title
        }
        /// The privacy status image
        var privacyStatusImage: UIImage? {
            if forceRed {
                return PEPColor.red.statusIconForMessage(enabled: true, withText: false)
            }
            return color.statusIconForMessage(enabled: true, withText: false)
        }
        /// The current language
        var currentLanguage: String
        /// Indicates if the trustwords are long
        var longTrustwords: Bool = false
        /// The privacy status in between the current user and the partner
        var privacyStatus: String?
        /// Status indicator
        var color : PEPColor {
            if forceRed {
                return PEPColor.red
            }
            return handshakeCombination.partnerIdentity.pEpColor()
        }
        var trustwords : String?
        //Prevents the overkill of require the trustwords when it's not necesary.
        fileprivate var shouldUpdateTrustwords : Bool = true
        fileprivate var forceRed: Bool = false
        /// The identity of the user to do the handshake
        fileprivate var handshakeCombination: TrustManagementUtil.HandshakeCombination
        fileprivate var fingerprint: String?
    }
}

/// View Model to handle the TrustManagementViewModel views.
final class TrustManagementViewModel {
    weak public var delegate : TrustManagementViewModelDelegate?
    weak public var protectionStateChangeDelegate: TrustmanagementProtectionStateChangeDelegate?
    public var pEpProtected : Bool {
        didSet {
            protectionStateChangeDelegate?.protectionStateChanged(to: pEpProtected)
        }
    }
    var shouldShowOptionsButton: Bool = false
    private var message: Message
    private var trustManagementUtil : TrustManagementUtilProtocol?
    private let undoManager = UndoManager()
    private var actionPerformed = [String]()
    
    /// Items to be displayed in the View Controller
    private (set) var rows: [Row] = [Row]()

    /// Constructor
    /// - Parameters:
    ///   - message: The message to manage the trust
    ///   - handshakeUtil: The tool to interact with the engine. It provides a default instance. The parameter is used for testing purposes.
    public init(message : Message,
                pEpProtectionModifyable: Bool,
                delegate : TrustManagementViewModelDelegate? = nil,
                protectionStateChangeDelegate: TrustmanagementProtectionStateChangeDelegate? = nil,
                trustManagementUtil: TrustManagementUtilProtocol? = TrustManagementUtil()) {
        self.message = message
        self.trustManagementUtil = trustManagementUtil
        self.pEpProtected = message.pEpProtected
        self.shouldShowOptionsButton = pEpProtectionModifyable
        self.delegate = delegate
        self.protectionStateChangeDelegate = protectionStateChangeDelegate
        generateRows()
    }

    ///MARK - Actions
    
    /// Reject the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
    public func handleRejectHandshakePressed(at indexPath: IndexPath) {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        let actionName = NSLocalizedString("Trust Rejection", comment: "Action name to be suggested at the moment of revert")
        actionPerformed.append(actionName)
        registerUndoAction(at: indexPath)
        let row = rows[indexPath.row]
        let identity : Identity = row.handshakeCombination.partnerIdentity.safeForSession(Session.main)
        rows[indexPath.row].fingerprint = trustManagementViewModel.getFingerprint(for: identity)
        rows[indexPath.row].forceRed = true
        trustManagementViewModel.denyTrust(for: identity)
        reevaluateMessage()
        delegate?.reload()
    }
    
    /// Confirm the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
    public func handleConfirmHandshakePressed(at indexPath: IndexPath) {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        let actionName = NSLocalizedString("Trust Confirmation", comment: "Action name to be suggested at the moment of revert")
        actionPerformed.append(actionName)
        registerUndoAction(at: indexPath)
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        let identity : Identity = row.handshakeCombination.partnerIdentity.safeForSession(Session.main)
        trustManagementViewModel.confirmTrust(for: identity)
        reevaluateMessage()
        delegate?.reload()
    }
    
    /// Handles the undo action.
    /// That means that the trust will be reseted.
    /// So it is not important what action in concrete was performed.
    /// - Parameter indexPath: The index path of the row from where the last action has been performed.
    @objc public func handleUndo(forRowAt indexPath: IndexPath) {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        let row = rows[indexPath.row]
        rows[indexPath.row].shouldUpdateTrustwords = true
        rows[indexPath.row].forceRed = false
        trustManagementViewModel.undoMisstrustOrTrust(for: row.handshakeCombination.partnerIdentity,
                                                      fingerprint: row.fingerprint)
        reevaluateMessage()
    }
    
    /// Handles the redey action
    /// - Parameter indexPath: The indexPath of the item to get the user to undo last action.
    public func handleResetPressed(forRowAt indexPath: IndexPath) {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        trustManagementViewModel.resetTrust(for: row.handshakeCombination.partnerIdentity)
        reevaluateMessage()
        delegate?.reload()
    }

    /// - returns: the available languages.
    public func handleChangeLanguagePressed(forRowAt indexPath : IndexPath) -> [String] {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModelDelegate is nil")
            return [String]()
        }
        rows[indexPath.row].shouldUpdateTrustwords = true
        guard let list = trustManagementViewModel.languagesList() else {
            Log.shared.error("The list of languages could be retrieved.")
            return [String]()
        }
        return list
    }
    
    /// Updates the selected language for that row.
    /// - Parameters:
    ///   - indexPath: The index path of the row
    ///   - language: The chosen language
    public func didSelectLanguage(forRowAt indexPath: IndexPath, language: String) {
        guard let trustManagementViewModelDelegate = delegate else {
            Log.shared.errorAndCrash("TrustManagementViewModelDelegate is nil")
            return
        }
        rows[indexPath.row].currentLanguage = language
        trustManagementViewModelDelegate.reload()
    }
    
    /// Toogle pEp protection status
    public func handleToggleProtectionPressed() {
        pEpProtected = !pEpProtected
    }

    /// Informs if is it possible to undo an action.
    /// - returns: Indicates if it's possible to undo an action.
    public func canUndo() -> Bool {
        return undoManager.canUndo
    }
    
    /// - returns: The name of the last action performed, nil if there isn't any.
    public func lastActionPerformed() -> String? {
        return actionPerformed.last
    }

    /// Method that makes the trustwords long or short (more or less trustwords in fact).
    /// - Parameter indexPath: The indexPath to get the row to toogle the status (long/short)
    public func handleToggleLongTrustwords(forRowAt indexPath: IndexPath) {
        guard let trustManagementViewModelDelegate = delegate else {
            Log.shared.errorAndCrash("TrustManagementViewModelDelegate is nil")
            return
        }
        rows[indexPath.row].shouldUpdateTrustwords = true
        rows[indexPath.row].longTrustwords.toggle()
        trustManagementViewModelDelegate.reload()
    }

    public typealias TrustWords = String
    
    /// Generate the trustwords
    /// - Parameters:
    ///   - indexPath: The indexPath of the row to toogle the status (long/short)
    ///   - long: Indicates if the trustwords MUST be long (more words)
    ///   - completion: the completion block to be executed once the trustwords are generated.
    /// If the trustwords passed are nil the UI must no be updated.
    public func generateTrustwords(forRowAt indexPath: IndexPath,
                                   long : Bool = false,
                                   completion: @escaping (TrustWords?) -> Void) {
        guard rows[indexPath.row].shouldUpdateTrustwords else {
            if let trustwords = rows[indexPath.row].trustwords {
                completion(trustwords)
                return
            }
            completion(nil)
            return
        }
        rows[indexPath.row].shouldUpdateTrustwords = false
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self,
                let trustManagementViewModel = me.trustManagementUtil else {
                completion(nil)
                Log.shared.errorAndCrash("Lost myself or the trustManagement ViewModel")
                return
            }
            let complete: (TrustWords?) -> Void = { trustwords in
                DispatchQueue.main.async {
                    completion(trustwords)
                }
            }
            let handshakeItem = me.rows[indexPath.row]
            handshakeItem.handshakeCombination.ownIdentity.session.performAndWait {
                let selfIdentity = handshakeItem.handshakeCombination.ownIdentity
                let partnerIdentity = handshakeItem.handshakeCombination.partnerIdentity
                guard let trustwords = try? trustManagementViewModel.getTrustwords(for: selfIdentity,
                                                                                   and: partnerIdentity,
                                                                                   language: handshakeItem.currentLanguage,
                                                                                   long: long)
                    else {
                        Log.shared.errorAndCrash("No Trustwords")
                        completion(nil)
                        return
                }
                me.rows[indexPath.row].trustwords = trustwords
                complete(trustwords)
            }
        }
    }

    /// Method that reverts the last action performed by the user
    /// After the execution of this method there won't be any action to un-do.
    public func shakeMotionDidEnd() {
       /// Evaluate it the undo manager can undo means if it has something registerd to undo.
        /// If so, undo it and reload the view.
        if (undoManager.canUndo) {
            undoManager.undo()
            delegate?.reload()
            _ = actionPerformed.popLast()
        }
    }

    ///MARK: - Private

    /// This must be called after every trust state change. The curently processed message might
    /// change color.
    private func reevaluateMessage() {
        message.session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.error("Lost myself - The message will not be reevaluated")
                return
            }
            RatingReEvaluator.reevaluate(message: me.message)
        }
    }

    /// Method that generates the rows to be used by the VC
    private func generateRows() {
        guard let trustManagementViewModel = trustManagementUtil else {
            Log.shared.errorAndCrash("TrustManagementViewModel is nil")
            return
        }
        let combinations = trustManagementViewModel.handshakeCombinations(message: message)
        combinations.forEach { (combination) in
            let backupLanguage = "en"
            let language =
            combination.partnerIdentity.language ?? Locale.current.languageCode ?? backupLanguage
            let row = Row(currentLanguage: language,
                          longTrustwords: false,
                          handshakeCombination: combination)
            rows.append(row)
        }
    }

    /// Register the action to be undone
    /// Is not important determine what action in concret must be undone.
    /// The trust management util -and thus, the engine- will take care of that.
    /// - Parameter indexPath: The indexPath of the row which the action to undo.
    private func registerUndoAction(at indexPath: IndexPath) {
        undoManager.registerUndo(withTarget: self,
                                 selector: #selector(handleUndo(forRowAt:)),
                                 object: indexPath)
    }
}

/// MARK: - Image 

extension TrustManagementViewModel {
    
    /// Method that returns the user image for the current indexPath throught the callback
    /// - Parameters:
    ///   - indexPath: The index path to get the user image
    ///   - complete: The callback with the image
    public func getImage(forRowAt indexPath: IndexPath, complete: @escaping (UIImage?) -> ()) {
        
        //Check if it's cached, use it if so.
        let handshakeItem : Row = rows[indexPath.row]
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
