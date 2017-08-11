//
//  MimeTypeUtil.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

open class MimeTypeUtil {
    static let defaultMimeType = "application/octet-stream"

    let comp = "MimeTypeUtil"
    var mimeTypeToExtension = [String: String]()
    var extensionToMimeType = [String: String]()

    public init?() {
        let resource = "jsonMimeType"
        let type = "txt"
        do {
            if let file = Bundle.main.path(forResource: resource, ofType: type) {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                guard let json = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String:Any] else {
                        return nil
                }
                guard let theData = json["mimeType"] as? [String: String] else {
                    return nil
                }
                for (theExtension, mimeType) in theData {
                    mimeTypeToExtension[mimeType.lowercased()] = theExtension
                    extensionToMimeType[theExtension.lowercased()] = mimeType
                }
            }
        } catch let error as NSError {
            Log.shared.error(component: comp, error: error)
            return nil
        }
    }

    open func fileExtension(mimeType: String) -> String? {
        return mimeTypeToExtension[mimeType.lowercased()]
    }

    open func mimeType(fileExtension: String) -> String {
        return extensionToMimeType[fileExtension.lowercased()] ?? MimeTypeUtil.defaultMimeType
    }

    /**
     Is the given mimetype suitable for creating an `UIImage`?
     */
    open func isImage(mimeType theMimeType: String) -> Bool {
        let lcMT = theMimeType.lowercased()
        if lcMT == mimeType(fileExtension: "png") || lcMT == mimeType(fileExtension: "jpg") {
            return true
        }
        return false
    }
}
