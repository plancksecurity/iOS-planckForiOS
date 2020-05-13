//
//  KeyImportModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PEPObjCAdapterFramework
import MessageModel

/// Model for importing keys from the filesystem, and setting them as own keys.
class KeyImportModel {
    public private(set) var rows = [Row]()

    init() {
        loadRows()
    }

    public func handleDidSelect(rowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            // developer error
            Log.shared.errorAndCrash("indexPath out of bounds: %d", indexPath.row)
            return
        }
        importKeyAndSetOwn(url: row.fileUrl)
    }
}

extension KeyImportModel {
    struct Row {
        public let fileUrl: URL

        public var fileName: String {
            fileUrl.fileName(includingExtension: true)
        }
    }
}

extension KeyImportModel {
    private func loadRows() {
        do {
            let urls = try FileBrowser.listFileUrls(fileTypes: [.key])
            rows = urls.map { Row(fileUrl: $0) }
        } catch {
            // developer error
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
            // TODO: Signal error
        }
    }
}
