//
//  TrustManagementViewModel.swift
//  pEp
//
//  Created by Martin Brude on 30/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

/// TrustManagementViewModel View Mode Delegate
protocol TrustManagementViewModelDelegate: AnyObject {
    /// Delegate method to notify that an action ends and the view must be reloaded.
    func reload()

    /// Called when data changed.
    func dataChanged(forRowAt indexPath: IndexPath)
}

protocol TrustmanagementProtectionStateChangeDelegate: AnyObject {
    /// Called whenever the user toggles protection state (for the message)
    func protectionStateChanged(to newValue: Bool)
}

extension TrustManagementViewModel {
    /// The item that represents the handshake partner
    public class Row {
        private let trustManagementUtil: TrustManagementUtilProtocol
        public typealias LanguageCode = String

        public init(language: LanguageCode,
                    handshakeCombination: TrustManagementUtil.HandshakeCombination,
                    trustManagementUtil: TrustManagementUtilProtocol? = nil,
                    completion: @escaping () -> ()) {
            _language = language
            self.handshakeCombination = handshakeCombination
            self.trustManagementUtil = trustManagementUtil ?? TrustManagementUtil()
            setupTrustwords(combination: handshakeCombination, language: language) {
                completion()
            }
        }

        /// Indicates the handshake partner's name
        public var name: String {
            let name = handshakeCombination.partnerIdentity.userName
            let address = handshakeCombination.partnerIdentity.address
            return name ?? address
        }

        /// The description for the row
        public func description(completion: @escaping (String) -> Void) {
            if forceRed {
                completion(Color.red.privacyStatusDescription)
            } else {
                color { (color) in
                    DispatchQueue.main.async {
                        completion(color.privacyStatusDescription)
                    }
                }
            }
        }

        /// The privacy status name
        public func privacyStatusName(completion: @escaping (String)->Void){
            guard !forceRed else {
                completion(String.trustIdentityTranslation(pEpRating: .underAttack).title)
                return
            }
            handshakeCombination.partnerIdentity.pEpRating { (rating) in
                let translations = String.trustIdentityTranslation(pEpRating: rating)
                DispatchQueue.main.async {
                    completion(translations.title)
                }
            }
        }

        /// The privacy status image
        public func privacyStatusImage(completion: @escaping (UIImage?) -> Void) {
            if forceRed {
                completion(Color.red.statusIconForMessage(enabled: true, withText: false))
            }else {
                color { (color) in
                    DispatchQueue.main.async {
                        completion(color.statusIconForMessage(enabled: true, withText: false))
                    }
                }
            }
        }

        /// The current language
        private var _language: String
        fileprivate func setLanguage(newLang: String, completion: @escaping ()->Void) {
            _language = newLang
            setupTrustwords(combination: handshakeCombination, language: _language) {
                completion()
            }
        }
        fileprivate var language: String {
            return _language
        }
        /// Indicates if the long (or the short) version of the trustwords should be shown
        var showLongTrustwordVersion: Bool = false
        /// Status indicator
        func color(completion: @escaping (Color) -> Void){
            if forceRed {
                completion(.red)
            } else {
                handshakeCombination.partnerIdentity.pEpColor { (color) in
                    DispatchQueue.main.async {
                        completion(color)
                    }
                }
            }
        }

        /// Mega ugly.
        /// Do not use with the expection of the following use case:
        /// In cellForRowAtIndexpath, there is no way without blocking. See implementi0on.
        func blockingColor() -> Color {
            var result = Color.noColor
            if forceRed {
                result = .red
            } else {
                let partner = handshakeCombination.partnerIdentity
                let group = DispatchGroup()
                group.enter()
                let queue = DispatchQueue(label: "blockColorQueue", qos: .userInteractive)
                queue.async {
                    let privateSession = Session()
                    let savePartner = partner.safeForSession(privateSession)
                    savePartner.pEpColor(session: privateSession) { (color) in
                        result = color
                        group.leave()
                    }
                }
                group.wait()
            }
            return result
        }

        public typealias TrustWords = String

        public var trustwords: TrustWords? {
            return showLongTrustwordVersion ? trustwordsLong : trustwordsShort
        }

        private var trustwordsShort: String?
        private var trustwordsLong: String?
        //Prevents the overkill of require the trustwords when it's not necesary.
        fileprivate var forceRed: Bool = false
        /// The identity of the user to do the handshake
        fileprivate var handshakeCombination: TrustManagementUtil.HandshakeCombination
        fileprivate var fingerprint: String?

        private func setupTrustwords(combination: TrustManagementUtil.HandshakeCombination,
                                     language: LanguageCode,
                                     completion: @escaping ()->Void) {
            let group = DispatchGroup()
            var longTw: String? = nil
            var shortTw: String? = nil
            group.enter()
            trustManagementUtil.getTrustwords(for: combination.ownIdentity,
                                              and: combination.partnerIdentity,
                                              language: language,
                                              long: true)
            { (trustwords) in
                longTw = trustwords
                group.leave()
            }
            group.enter()
            trustManagementUtil.getTrustwords(for: combination.ownIdentity,
                                              and: combination.partnerIdentity,
                                              language: language,
                                              long: false)
            { (trustwords) in
                shortTw = trustwords
                group.leave()
            }
            group.notify(queue: DispatchQueue.main) { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    // Do nothing.
                    return
                }

                me.trustwordsLong = me.prepareTrustwordStringForDisplay(trustwords: longTw)

                if let tmp = shortTw {
                    // Short TWs must have three dots for signaling as truncated
                    shortTw = "\(tmp)…"
                }
                me.trustwordsShort = me.prepareTrustwordStringForDisplay(trustwords: shortTw)
                completion()
            }
        }

        private func prepareTrustwordStringForDisplay(trustwords: TrustWords?) -> TrustWords? {
            guard let trustwords = trustwords else {
                // This is a valid case. Eg. contacts with no color have no trustwords.
                return nil
            }
            let oneSpace = " "
            let threeSpaces = "   "
            return trustwords.replacingOccurrences(of: oneSpace, with: threeSpaces)
        }

    }
}

/// View Model to handle the TrustManagementViewModel views.
final class TrustManagementViewModel {
    weak public var delegate : TrustManagementViewModelDelegate?
    weak public var protectionStateChangeDelegate: TrustmanagementProtectionStateChangeDelegate?
    private let persistRatingChangesForMessage: Bool
    public var pEpProtected : Bool {
        didSet {
            protectionStateChangeDelegate?.protectionStateChanged(to: pEpProtected)
        }
    }
    var shouldShowOptionsButton: Bool = false
    private var message: Message
    private var trustManagementUtil : TrustManagementUtilProtocol
    private let undoManager = UndoManager()
    /// It contains the names of the actions that are going to revert previously executed actions.
    /// For example: 'Undo Trust Rejection'. In case the last action was a Trust Rejection.
    /// - Note: Must be already localized.
    private var revertActionNames = [String]()
    
    /// Items to be displayed in the View Controller
    private (set) var rows: [Row] = [Row]()

    /// Constructor
    /// - Parameters:
    ///   - message: The message to manage the trust
    ///   - handshakeUtil: The tool to interact with the engine. It provides a default instance. The parameter is used for testing purposes.
    public init(message : Message,
                pEpProtectionModifyable: Bool,
                persistRatingChangesForMessage: Bool = true,
                delegate: TrustManagementViewModelDelegate? = nil,
                protectionStateChangeDelegate: TrustmanagementProtectionStateChangeDelegate? = nil,
                trustManagementUtil: TrustManagementUtilProtocol? = nil) {
        self.message = message
        self.trustManagementUtil = trustManagementUtil ?? TrustManagementUtil()
        let safeMessage = message.safeForSession(Session.main)
        self.pEpProtected = safeMessage.pEpProtected
        self.shouldShowOptionsButton = pEpProtectionModifyable
        self.persistRatingChangesForMessage = persistRatingChangesForMessage
        self.delegate = delegate
        self.protectionStateChangeDelegate = protectionStateChangeDelegate
        setupRows()
    }

    ///MARK - Actions
    
    /// Reject the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to reject the handshake
    public func handleRejectHandshakePressed(at indexPath: IndexPath) {
        let actionName = NSLocalizedString("Undo Trust Rejection", comment: "Action name to be suggested at the moment of revert")
        revertActionNames.append(actionName)
        registerUndoAction(at: indexPath)
        let row = rows[indexPath.row]
        let identity : Identity = row.handshakeCombination.partnerIdentity.safeForSession(Session.main)
        trustManagementUtil.getFingerprint(for: identity) { [weak self] theFpr in
            DispatchQueue.main.async {
                guard let me = self else {
                    // UI, can happen
                    return
                }
                me.rows[indexPath.row].fingerprint = theFpr
                me.rows[indexPath.row].forceRed = true
                me.trustManagementUtil.denyTrust(for: identity) { [weak self] _ in
                    DispatchQueue.main.async {
                        guard let me = self else {
                            // UI, can happen
                            return
                        }
                        me.reevaluateMessage(forRowAt: indexPath)
                    }
                }
            }
        }
    }
    
    /// Confirm the handshake
    /// - Parameter indexPath: The indexPath of the item to get the user to confirm the handshake
    public func handleConfirmHandshakePressed(at indexPath: IndexPath) {
        let actionName = NSLocalizedString("Undo Trust Confirmation", comment: "Action name to be suggested at the moment of revert")
        revertActionNames.append(actionName)
        registerUndoAction(at: indexPath)
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        let identity : Identity = row.handshakeCombination.partnerIdentity.safeForSession(Session.main)
        trustManagementUtil.confirmTrust(for: identity) { [weak self] _ in
            DispatchQueue.main.async {
                guard let me = self else {
                    // UI, can happen
                    return
                }
                // Note that the message is reevaluated regardless of errors
                me.reevaluateMessage(forRowAt: indexPath)
            }
        }
    }
    
    /// Handles the undo action.
    /// That means that the trust will be reseted.
    /// So it is not important what action in concrete was performed.
    /// - Parameter indexPath: The index path of the row from where the last action has been performed.
    @objc public func handleUndo(forRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        trustManagementUtil.undoMisstrustOrTrust(for: row.handshakeCombination.partnerIdentity,
                                                 fingerprint: row.fingerprint) { [weak self] _ in
            DispatchQueue.main.async {
                guard let me = self else {
                    // UI, can happen
                    return
                }
                // Note that the message is reevaluated regardless of errors
                me.reevaluateMessage(forRowAt: indexPath)
            }
        }
    }
    
    /// Handles the redey action
    /// - Parameter indexPath: The indexPath of the item to get the user to undo last action.
    public func handleResetPressed(forRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        rows[indexPath.row].forceRed = false
        trustManagementUtil.resetTrust(for: row.handshakeCombination.partnerIdentity,
                                       completion: { [weak self] in
                                        DispatchQueue.main.async {
                                            guard let me = self else {
                                                // UI, can happen
                                                return
                                            }
                                            me.reevaluateMessage(forRowAt: indexPath)
                                        }
                                       })
    }

    /// - returns: the available languages.
    public func languages(completion: @escaping ([String]) -> ()) {
        return trustManagementUtil.languagesList(completion: completion)
    }
    
    /// Updates the selected language for that row.
    /// - Parameters:
    ///   - indexPath: The index path of the row
    ///   - language: The chosen language
    public func handleDidSelect(language: String, forRowAt indexPath: IndexPath) {
        rows[indexPath.row].setLanguage(newLang: language) { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing.
                return
            }
            me.delegate?.dataChanged(forRowAt: indexPath)
        }
    }
    
    /// Toogle pEp protection status
    public func handleToggleProtectionPressed() {
        pEpProtected.toggle()
    }

    /// Informs if is it possible to undo an action.
    /// - returns: Indicates if it's possible to undo an action.
    public func canUndo() -> Bool {
        return undoManager.canUndo
    }
    
    /// - returns: The name of the action to revert the last one performed, nil if there isn't any.
    public func revertAction() -> String? {
        return revertActionNames.last
    }

    /// Method that makes the trustwords long or short (more or less trustwords in fact).
    /// - Parameter indexPath: The indexPath to get the row to toogle the status (long/short)
    public func handleToggleLongTrustwords(forRowAt indexPath: IndexPath) {
        rows[indexPath.row].showLongTrustwordVersion.toggle()
        delegate?.dataChanged(forRowAt: indexPath)
    }

    /// Method that reverts the last action performed by the user
    /// After the execution of this method there won't be any action to un-do.
    public func handleShakeMotionDidEnd() {
       /// Evaluate it the undo manager can undo means if it has something registerd to undo.
        /// If so, undo it and reload the view.
        if (undoManager.canUndo) {
            undoManager.undo()
            delegate?.reload()
            _ = revertActionNames.popLast()
        }
    }

    ///MARK: - Private

    /// Re-computes the messages rating, saves the message and informs the delegate about a possible data change.
    /// This must be called after every trust state change. The curently processed message might
    /// change color.
    /// - Note: Will be called from background queues.
    private func reevaluateMessage(forRowAt indexPath: IndexPath) {
        message.session.performAndWait { [weak self] in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                return
            }
            RatingReEvaluator.reevaluate(message: me.message,
                                         storeMessageWhenDone: me.persistRatingChangesForMessage) {
                DispatchQueue.main.async {
                    me.delegate?.dataChanged(forRowAt: indexPath)
                }
            }
        }
    }

    /// Method that generates the rows to be used by the VC
    private func setupRows() {
        trustManagementUtil.handshakeCombinations(message: message) { [weak self] (combinations) in
            guard let me = self else {
                // Valid case. We might have been dismissed already.
                // Do nothing.
                return
            }

            let rowsLoadedGroup = DispatchGroup()

            for combination in combinations{
                let backupLanguage = "en"
                let language =
                combination.partnerIdentity.language ?? Locale.current.languageCode ?? backupLanguage

                rowsLoadedGroup.enter()

                let row = Row(language: language,
                              handshakeCombination: combination,
                              trustManagementUtil: me.trustManagementUtil) {
                                rowsLoadedGroup.leave()
                }
                me.rows.append(row)
            }

            rowsLoadedGroup.notify(queue: DispatchQueue.main) { [weak self] in
                guard let me = self else {
                    // Valid case. We might have been dismissed already.
                    // Do nothing.
                    return
                }
                me.delegate?.reload()
            }
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

// MARK: - Image 

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
            DispatchQueue.main.async {
                complete(cachedContactImage)
            }
            return
        }
        
        //If can't find the image in the cache, creates it from the session.
        let session = Session()
        let safePartnerIdentity = partnerIdentity.safeForSession(session)
        DispatchQueue.global(qos: .userInteractive).async {
            session.performAndWait {
                if let contactImage = contactImageTool.identityImage(for:
                    IdentityImageTool.IdentityKey(identity: safePartnerIdentity)) {
                    DispatchQueue.main.async {
                        complete(contactImage)
                    }
                }
            }
        }
    }
}
