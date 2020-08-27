//
//  KeyImportViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PEPObjCAdapterFramework
import MessageModel

protocol KeyImportViewModelDelegate: class {
    /// The rows have been loadad.
    func rowsLoaded()

    /// The key was successfully imported, ask for permission to set it as an own key.
    func showConfirmSetOwnKey(keys: [KeyImportViewModel.KeyDetails])

    /// An error ocurred, either during key import or set own key.
    func showError(message: String)

    /// The key was successfully set as own key
    func showSetOwnKeySuccess()
}

extension KeyImportViewModel {
    struct Row {
        public var fileName: String {
            fileUrl.fileName(includingExtension: true)
        }

        fileprivate let fileUrl: URL
    }
}

extension KeyImportViewModel {
    /// Passed between VM and VC to provide the user with data and uniquely identify
    /// keys to operate on.
    struct KeyDetails {
        public let address: String
        public let fingerprint: String

        /// - Returns: A string representing user name (if set) and email of this key,
        /// as in "user ID" of GPG/PGP, e.g. "Eldon Tyrell <eldon.tyrell@tyrell.corp>"
        /// or "eldon.tyrell@tyrell.corp" if the user name is missing.
        public func userPresentableNameAndAddress() -> String {
            if let theUserName = userName {
                return "\(theUserName) <\(address)>"
            } else {
                return address
            }
        }

        private let userName: String?

        init(address: String, fingerprint: String, userName: String?) {
            self.address = address
            self.fingerprint = fingerprint
            self.userName = userName
        }

        func prettyFingerprint() -> String {
            var theFingerprint = fingerprint

            let fprDist = theFingerprint.distance(from: theFingerprint.startIndex,
                                                  to: theFingerprint.endIndex)

            var index = theFingerprint.startIndex
            for _ in 1...fprDist/2 {
                index = theFingerprint.index(after: index)
            }
            theFingerprint.insert("\n", at: index)

            return theFingerprint
        }
    }

    /// - Returns: A user-presentable list of fingerprints representing the given key details.
    public func userPresentableFingerprints(keyDetails: [KeyDetails]) -> String {
        let fingerprintStrings = keyDetails.map { $0.prettyFingerprint() }
        let fingerprintString = fingerprintStrings.joined(separator: ", ")
        return fingerprintString
    }

    /// - Returns: A user-presentable list of names representing the given key details.
    public func userPresentableNames(keyDetails: [KeyDetails]) -> String {
        let presentationStrings = keyDetails.map { $0.userPresentableNameAndAddress() }
        let presentationString = presentationStrings.joined(separator: ", ")
        return presentationString
    }
}

/// Model for importing keys from the filesystem, and setting them as own keys.
class KeyImportViewModel {
    weak public var delegate: KeyImportViewModelDelegate?

    public private(set) var rows = [Row]()

    public init(documentsBrowser: DocumentsDirectoryBrowserProtocol = DocumentsDirectoryBrowser(),
         keyImporter: KeyImportUtilProtocol = KeyImportUtil()) {
        self.documentsBrowser = documentsBrowser
        self.keyImporter = keyImporter
    }

    /// Search for key file URLs and list them.
    public func loadRows() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                return // The handling VC can go out of scope
            }

            do {
                let urls = try me.documentsBrowser.listFileUrls(fileTypes: [.key])
                DispatchQueue.main.async {
                    me.rows = urls.map { Row(fileUrl: $0) }
                    me.checkDelegate()?.rowsLoaded()
                }
            } catch {
                // developer error
                Log.shared.errorAndCrash(error: error)
                me.rows = []
            }
        }
    }

    /// The user has tapped a row, which starts loading (importing) the underlying key
    /// asynchronously and informs the delegate about success.
    public func handleDidSelect(rowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            // developer error
            Log.shared.errorAndCrash("indexPath out of bounds: %d", indexPath.row)
            return
        }
        importKey(url: row.fileUrl)
    }

    /// Sets the given key as own and informs the delegate about success or error.
    public func setOwnKeys(keys: [KeyImportViewModel.KeyDetails]) {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let me = self else {
                return // The handling VC can go out of scope
            }

            for key in keys {
                me.keyImporter.setOwnKey(address: key.address,
                                         fingerprint: key.fingerprint,
                                         errorCallback: { error in
                                            guard let _ = error as? KeyImportUtil.SetOwnKeyError else {
                                                Log.shared.errorAndCrash(message: "Unexpected error have to handle it: \(error)")
                                                return
                                            }
                                            DispatchQueue.main.async {
                                                me.checkDelegate()?.showError(message: me.keyImportErrorMessage)
                                            }
                }) {
                    DispatchQueue.main.async {
                        me.checkDelegate()?.showSetOwnKeySuccess()
                    }
                }
            }
        }
    }

    private let documentsBrowser: DocumentsDirectoryBrowserProtocol
    private let keyImporter: KeyImportUtilProtocol

    // One message to rule them all
    fileprivate let keyImportErrorMessage = NSLocalizedString("Error occurred. No key imported.",
                                                              comment: "Generic error message on trying to import a key")
}

extension KeyImportViewModel {
    private func importKey(url: URL) {
        keyImporter.importKey(url: url,
                              errorCallback: { [weak self] error in
                                // weak self because it's UI and the VC/VM can go out of scope
                                guard let me = self else {
                                    return
                                }

                                DispatchQueue.main.async {
                                    if let theError = error as? KeyImportUtil.ImportError {
                                        switch theError {
                                        case .cannotLoadKey:
                                            me.checkDelegate()?.showError(message: me.keyImportErrorMessage)
                                        case .malformedKey:
                                            me.checkDelegate()?.showError(message: me.keyImportErrorMessage)
                                        }
                                    } else {
                                        Log.shared.errorAndCrash(message: "Unhandled error. Check all possible cases.")
                                        me.checkDelegate()?.showError(message: me.keyImportErrorMessage)
                                    }
                                }
            },
                              completion: { [weak self] keyDatas in
                                // weak self because it's UI and the VC/VM can go out of scope
                                guard let me = self else {
                                    return
                                }
                                let keyDetails = keyDatas.map {
                                    KeyDetails(address: $0.address,
                                               fingerprint: $0.fingerprint,
                                               userName: $0.userName)
                                }
                                DispatchQueue.main.async {
                                    me.checkDelegate()?.showConfirmSetOwnKey(keys: keyDetails)
                                }
        })
    }

    private func checkDelegate() -> KeyImportViewModelDelegate? {
        guard let theDelegate = delegate else {
            Log.shared.errorAndCrash(message: "No delegate")
            return nil
        }
        return theDelegate
    }
}
