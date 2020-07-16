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
                DispatchQueue.main.async {
                    completion(nil, rating.pEpColor())
                }
            } catch let error as NSError {
                completion(error, nil)
            }
        }
    }

    private static let queue = DispatchQueue(label: "AdapterWrapper",
                                             qos: .userInitiated,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
}
