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

    public static func reEvaluateMessage(_ message: PEPMessage,
                                         xKeyList: [String]?,
                                         completion: @escaping (_ error: Error?, _ status: PEPStatus?, _ rating: PEPRating?) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                var status: PEPStatus = .unknownError
                var rating: PEPRating = .undefined
                try session.reEvaluateMessage(message,
                                              xKeyList: xKeyList,
                                              rating: &rating,
                                              status: &status)
                completion(nil, status, rating)
            } catch {
                completion(error, nil, nil)
            }
        }
    }

    public static func outgoingRating(for theMessage: PEPMessage,
                                      errorHandler: @escaping (_ error: Error) -> Void,
                                      completion: @escaping (_ rating: PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.outgoingRating(for: theMessage).pEpRating
                completion(rating)
            } catch {
                errorHandler(error)
            }
        }
    }

    public static func outgoingRatingPreview(for theMessage: PEPMessage,
                                             errorHandler: @escaping (_ error: Error) -> Void,
                                             completion: @escaping (_ rating: PEPRating) -> Void) {
        queue.async {
            let session = PEPSession()
            do {
                let rating = try session.outgoingRatingPreview(for: theMessage).pEpRating
                completion(rating)
            } catch {
                errorHandler(error)
            }
        }
    }

    private static let queue = DispatchQueue(label: "AdapterWrapper",
                                             qos: .userInitiated,
                                             attributes: .concurrent,
                                             autoreleaseFrequency: .inherit,
                                             target: nil)
}
