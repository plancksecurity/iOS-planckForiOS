//
//  AdapterWrapper.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

public class AdapterWrapper {
    public static func pEpColor(cdIdentity: CdIdentity,
                                completion: @escaping (_ error: Error?, _ color: PEPColor?) -> Void) {
        let pepC = cdIdentity.pEpIdentity()
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.rating(for: pepC).pEpRating
                let color = session.color(from: rating)
                DispatchQueue.main.async {
                    completion(nil, color)
                }
            } catch let error as NSError {
                completion(error, nil)
            }
        }
    }

    public static func pEpColor(pEpRating: PEPRating?) -> PEPColor {
        if let rating = pEpRating {
            return PEPSession().color(from: rating)
        } else {
            return PEPColor.noColor
        }
    }

    private static let queue = DispatchQueue(label: "AdapterWrapper",
                                             qos: .userInitiated,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
}
