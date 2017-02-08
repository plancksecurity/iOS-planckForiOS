//
//  MimeTypeUtil.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 08/02/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

open class MimeTypeUtil {

    open static func getMimeType(Extension:String) -> String {
        let path = Bundle.main.path(forResource: "jsonMimeType", ofType: "txt")

        //reading
        do {
            //let text2 = try String(contentsOf: path, encoding: String.Encoding.utf8)
            if let file = path {
                let data = try Data(contentsOf: URL(fileURLWithPath: file))

                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] {
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
        catch {/* error handling here */}
        return "application/octet-stream"
    }
}
