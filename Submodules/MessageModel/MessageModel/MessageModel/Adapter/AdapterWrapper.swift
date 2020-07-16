//
//  AdapterWrapper.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 16.07.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// Wraps UI calls into the adapter.
///
/// UI code cannot access adapter methods directly, since the adapter may
/// trigger passphrase UI and wait for an answer, which leads to deadlocks.
///
/// For that reason, the UI must not use `PEPSession` directly, but instead
/// use the methods from this class with a completion block.
///
/// The adapter will be called on a background queue and invoke the
/// completion block on the main queue with the result.
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
