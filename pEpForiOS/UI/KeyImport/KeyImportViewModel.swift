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

extension KeyImportViewModel {
    struct Row {
        fileprivate let fileUrl: URL

        public var fileName: String {
            fileUrl.fileName(includingExtension: true)
        }

        // TODO: This violates our coding guidelines
        // ("In the app target, the visibility MUST be private or public")
        let fileUrl: URL
    }
}

extension KeyImportViewModel {
    /// Errors that can occur when importing a key, and setting it as own key
    public enum KeyImportError: Error {
        /// The key could not even be loaded
        case cannotLoadKey

        /// The key could be loadad, but not processed
        case malformedKey

        /// No matching account could be found
        case noMatchingAccount

        /// The key could not be set as an own key
        case cannotSetOwnKey
    }
}

/// ViewModel for importing keys from the filesystem, and setting them as own keys (PGPKeyImport).
class KeyImportViewModel {
    public private(set) var rows = [Row]()

    init() {
        loadRows()
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            Log.shared.errorAndCrash("indexPath out of bounds: %d", indexPath.row)
            return
        }
        importKeyAndSetOwn(url: row.fileUrl)
    }
}

// MARK: - Private

extension KeyImportViewModel {
    private func loadRows() {
        do {
            let urls = try documentsBrowser.listFileUrls(fileTypes: [.key])
            rows = urls.map { Row(fileUrl: $0) }
        } catch {
            Log.shared.errorAndCrash(error: error)
            rows = []
        }
    }

    private func importKeyAndSetOwn(url: URL) {
        do {
            let dataString = try String(contentsOf: url)

            let session = PEPSession()

            let identities = try session.importKey(dataString)

            guard let firstIdentity = identities.first else {
                // TODO: Signal error
                return
            }

            guard let fingerprint = firstIdentity.fingerPrint else {
                // TODO: Signal error
                return
            }

            guard let account = Account.by(address: firstIdentity.address) else {
                // TODO: Signal error
                return
            }

            try account.user.setOwnKey(fingerprint: fingerprint)
        } catch {
            //!!!: TODO: Signal error
        }
    }
}
