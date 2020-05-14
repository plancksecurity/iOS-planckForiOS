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
    /// The key was successfully imported.
    /// - Parameter row: Model information about the imported key
    /// - Parameter keyData: Key details (e.g. address)
    func keyImportedSucceeded(row: KeyImportViewModel.Row, keyData: KeyImportUtil.KeyData)

    /// The key import failed.
    /// - Parameter row: Model information about the imported key
    /// - Parameter error: The error that ocurred
    func keyImportFailed(row: KeyImportViewModel.Row, error: KeyImportUtil.ImportError)

    /// The key was successfully installed as own key for the matching account
    /// - Parameter keyData: Key details (e.g. address)
    func setOwnKeySucceeded(keyData: KeyImportUtil.KeyData)

    /// The key was successfully installed as own key for the matching account
    /// - Parameter keyData: Key details (e.g. address)
    /// - Parameter error: The error that ocurred
    func setOwnKeyFailed(keyData: KeyImportUtil.KeyData, error: KeyImportUtil.SetOwnKeyError)
}

extension KeyImportViewModel {
    struct Row {
        public var fileName: String {
            fileUrl.fileName(includingExtension: true)
        }

        fileprivate let fileUrl: URL
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

    /// After the user has indicate the will to set this key as an own key,
    /// call this method, which asynchronously sets the key as own key
    /// and calls the delegate to inform about success or errors.
    public func setOwn(keyData: KeyImportUtil.KeyData) {
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
