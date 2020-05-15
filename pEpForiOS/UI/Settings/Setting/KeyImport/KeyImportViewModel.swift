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

protocol KeyImportViewModelDelegate {
    /// The key was successfully imported, ask for permission to set it as an own key.
    func showConfirmSetOwnKey(key: KeyImportViewModel.KeyDetails)

    /// An error ocurred, either during key import or set own key.
    func showError(with title: String, message: String)

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
    public private(set) var rows = [Row]()

    init(documentsBrowser: DocumentsDirectoryBrowserProtocol, keyImporter: KeyImportUtilProtocol) {
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
    }

    private let documentsBrowser: DocumentsDirectoryBrowserProtocol
    private let keyImporter: KeyImportUtilProtocol
}

extension KeyImportViewModel {
    private func loadRows() {
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
    }
}
