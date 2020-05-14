//
//  DocumentsDirectoryBrowserProtocol.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

public enum DocumentsDirectoryBrowserFileType {
    /// ASCII-armored public/private keys
    case key

    /// Supported file extensions (minus the dot).
    /// - Returns: The file extensions for a file type.
    public func fileExtensions() -> Set<String> {
        switch self {
        case .key:
            return Set(["asc"])
        }
    }
}

public protocol DocumentsDirectoryBrowserProtocol {
    func listFileUrls(fileTypes: [DocumentsDirectoryBrowserFileType]) throws -> [URL]
}
