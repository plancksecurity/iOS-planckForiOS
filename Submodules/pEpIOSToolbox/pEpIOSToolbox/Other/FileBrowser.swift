//
//  FileBrowser.swift
//  pEpIOSToolbox
//
//  Created by Dirk Zimmermann on 13.05.20.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import Foundation

/// Methods for listing files in the app's documents directory.
public class FileBrowser {
    public enum FileType {
        /// ASCII-armored public/private keys
        case keys
    }

    /// Retrieves an array of file URLs found in the documents directories,
    /// without recursion.
    /// - Parameter fileTypes: An array of file types, which translates to a set of
    /// desired file extensions.
    /// - Throws: Exceptions by FileManager methods.
    /// - Returns: An array of file URLs that match the given file type.
    public func listFileUrls(fileTypes: [FileType]) throws -> [URL] {
        var resultUrls = [URL]()

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for theUrl in urls {
            let fileUrls = try FileManager.default.contentsOfDirectory(at: theUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsHiddenFiles])
            for theFileUrl in fileUrls {
            }
        }

        return resultUrls
    }
}
