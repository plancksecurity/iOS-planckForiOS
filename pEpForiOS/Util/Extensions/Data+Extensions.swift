//
//  NSData+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

extension Data {
    public func stringEncodingFromIANACharset(_ charset: String) -> String.Encoding {
        let enc = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(enc))
    }

    public func toStringWithIANACharset(_ charset: String?) -> String? {
        if let cs = charset {
            let enc = stringEncodingFromIANACharset(cs)
            return String(data: self, encoding: enc)?.applyingDos2Unix()
        } else {
            return String(data: self, encoding: String.Encoding.utf8)?.applyingDos2Unix()
        }
    }

    public func debugSave(basePath: String, fileName: String, ext: String = "data") {
        let dateDesc = Date().description(with: nil)
        let filePath = "\(basePath)/\(fileName)_\(dateDesc).\(ext)"
        let url = URL(fileURLWithPath: filePath)
        do {
            try write(to: url)
        } catch {
            Logger(category: Logger.util).error("Could not save to %{public}@", url.absoluteString)
        }
    }

    public func debugSaveAsJson(basePath: String, fileName: String, ext: String = "data") {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: self, options: .prettyPrinted)
            jsonData.debugSave(basePath: basePath, fileName: fileName, ext: ext)
        } catch let err {
            Logger(category: Logger.util).error("%{public}@", err.localizedDescription)
        }
    }
}
