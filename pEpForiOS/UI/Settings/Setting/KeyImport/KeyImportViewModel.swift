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
    /// The key was successfully imported, ask for permission to set it as an own key.
    func showConfirmSetOwnKey(key: KeyImportViewModel.KeyDetails)

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
    }
}

/// Model for importing keys from the filesystem, and setting them as own keys.
class KeyImportViewModel {
    weak public var delegate: KeyImportViewModelDelegate?

    public private(set) var rows = [Row]()

    init(documentsBrowser: DocumentsDirectoryBrowserProtocol = DocumentsDirectoryBrowser(),
         keyImporter: KeyImportUtilProtocol = KeyImportUtil()) {
        self.documentsBrowser = documentsBrowser
        self.keyImporter = keyImporter

        loadRows()
    }

    /// The user has tapped a row, which starts loading (importing) the underlying key
    /// asynchronously and informs the delegate about success.
    public func handleDidSelect(rowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            // developer error
            Log.shared.errorAndCrash("indexPath out of bounds: %d", indexPath.row)
            return
        }
        importKeyAndSetOwn(url: row.fileUrl)
    }

    /// Sets the given key as own and informs the delegate about success or error.
    func setOwnKey(key: KeyImportViewModel.KeyDetails) {
        // TODO: Make async
        do {
            try keyImporter.setOwnKey(address: key.address, fingerprint: key.fingerprint)
        } catch {
            guard let _ = error as? KeyImportUtil.SetOwnKeyError else {
                Log.shared.errorAndCrash(message: "Unexpected error have to handle it: \(error)")
                return
            }
            checkDelegate()?.showError(message: keyImportErrorMessage)
        }
    }

    private let documentsBrowser: DocumentsDirectoryBrowserProtocol
    private let keyImporter: KeyImportUtilProtocol

    // One message to rule them all
    let keyImportErrorMessage = NSLocalizedString("Error occurred. No key imported.",
                                                  comment: "Generic error message on trying to import a key")
}

extension KeyImportViewModel {
    private func loadRows() {
        // TODO: Make async
        do {
            let urls = try documentsBrowser.listFileUrls(fileTypes: [.key])
            rows = urls.map { Row(fileUrl: $0) }
        } catch {
            // developer error
            Log.shared.errorAndCrash(error: error)
            rows = []
        }
    }

    private func importKeyAndSetOwn(url: URL) {
        // TODO: Make async
        do {
            let keyData = try keyImporter.importKey(url: url)
            checkDelegate()?.showConfirmSetOwnKey(key: KeyDetails(address: keyData.address,
                                                                  fingerprint: keyData.fingerprint))
        } catch {
            if let theError = error as? KeyImportUtil.ImportError {
                switch theError {
                case .cannotLoadKey:
                    checkDelegate()?.showError(message: keyImportErrorMessage)
                case .malformedKey:
                    checkDelegate()?.showError(message: keyImportErrorMessage)
                }
            } else {
                Log.shared.errorAndCrash(message: "Unhandled error. Check all possible cases.")
                checkDelegate()?.showError(message: keyImportErrorMessage)
            }
        }
    }

    private func checkDelegate() -> KeyImportViewModelDelegate? {
        guard let theDelegate = delegate else {
            Log.shared.errorAndCrash(message: "No delegate")
            return nil
        }
        return theDelegate
    }
}
