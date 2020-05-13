//
//  KeyImportModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

/// Model for importing keys from the filesystem, and setting them as own keys.
class KeyImportModel {
    public private(set) var rows = [Row]()

    init() {
        loadRows()
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
            Log.shared.errorAndCrash(error: error)
            rows = []
        }
    }
}
