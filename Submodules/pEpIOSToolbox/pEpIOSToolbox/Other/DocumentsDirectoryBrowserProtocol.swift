//
//  DocumentsDirectoryBrowserProtocol.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 14.05.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

/// An enum of file types for `DocumentsDirectoryBrowserProtocol`,
/// where every type translates to a set of extensions for this file type.
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
    /// List the URLs of files from the documents directories.
    /// - Parameter fileTypes: The file types that should be listed, which translates
    /// to a list of file extensions to check for.
    /// - Note: The search does not recurse into subdirectories.
    /// - Throws: All `FileManager` related errors.
    func listFileUrls(fileTypes: [DocumentsDirectoryBrowserFileType]) throws -> [URL]
}
