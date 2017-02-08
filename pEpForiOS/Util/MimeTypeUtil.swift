//
//  MimeTypeUtil.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

open class MimeTypeUtil {
    open static let comp = "MimeTypeUtil"

    open static func getMimeType(Extension:String) -> String {
        do {
            if let file = Bundle.main.path(forResource: "jsonMimeType", ofType: "txt") {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))
                if let json = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String:Any] {
                    if let ex = json["mimeType"] as? [String : String] {
                        for (key,value) in ex {
                            if key == Extension.lowercased() {
                                return value as String
                            }
                        }
                    }
                }
            }
        }
        catch let error as NSError {
            Log.shared.error(component: comp, error: error)
        }
        return "application/octet-stream"
    }
}
