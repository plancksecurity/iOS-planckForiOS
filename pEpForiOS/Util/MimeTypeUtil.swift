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
    var json : [String : Any]?

    public init?() {
        let resource = "jsonMimeType"
        let type = "txt"
        do {
            if let file = Bundle.main.path(forResource: resource, ofType: type) {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                json = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String:Any]
            }
        } catch let error as NSError {
            Log.shared.error(component: comp, error: error)
            return nil
        }
    }
    
    open func getMimeType(fileExtension:String) -> String {
        if let data = json {
            if let ex = data["mimeType"] as? [String : String] {
                for (key,value) in ex {
                    if key == fileExtension.lowercased() {
                        return value as String
                    }
                }
            }
        }
        return MimeTypeUtil.defaultMimeType
    }
}
