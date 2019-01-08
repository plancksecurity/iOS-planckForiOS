//
//  FixAttachmentsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData
import Photos

import MessageModel

/**
 When getting an image from the device, we might get no data but a URL to the data.
 Use this operation to (down)load attachment content before sending such an image attachment.
 */
public class FixAttachmentsOperation: ConcurrentBaseOperation {
    let pInvalidLength = NSPredicate(format: "length = 0 and data != nil")
    let pInvalidData = NSPredicate(format: "data = nil and (fileName != nil or assetUrl != nil)")

    var openFetchCount = 0

    private let logger = Logger(category: Logger.backend)

    override public func main() {
        if isCancelled {
            markAsFinished()
            return
        }
        privateMOC.perform {
            self.fixAttachments(context: self.privateMOC)
        }
    }

    func fixZeroSizeAttachments(context: NSManagedObjectContext) -> Int {
        var changedAttachmentsCount = 0

        if let cdAttachments1 = CdAttachment.all(predicate: pInvalidLength, orderedBy: nil,
                                                 in: context)
            as? [CdAttachment] {
            for cdAttach in cdAttachments1 {
                if let theData = cdAttach.data {
                    changedAttachmentsCount += 1
                    cdAttach.length = Int64(theData.count)
                }
            }
        }

        return changedAttachmentsCount
    }

    func fixNilDataAttachments(context: NSManagedObjectContext, handler: @escaping (Int) -> ()) {
        guard let cdAttachments2 = CdAttachment.all(predicate: pInvalidData, orderedBy: nil,
                                                    in: context)
            as? [CdAttachment] else {
                handler(0)
                return
        }
        let totalCount = cdAttachments2.count
        if totalCount == 0 {
            handler(0)
        } else {
            openFetchCount = totalCount
            for cdAttach in cdAttachments2 {
                if let urlString = cdAttach.assetUrl ?? cdAttach.fileName {
                    let theURL = URL(string: urlString)
                    FixAttachmentsOperation.retrieveData(fromURL: theURL) { data in
                        context.perform {
                            if let theData = data {
                                cdAttach.data = theData
                                context.saveAndLogErrors()
                            }
                            self.openFetchCount -= 1
                            if self.openFetchCount == 0 {
                                handler(totalCount)
                            }
                        }
                    }
                } else {
                    Log.error(component: comp, errorString: "CdAttachment with invalid URL")
                    openFetchCount -= 1
                }
            }
        }
    }

    /**
     Might be useful for debugging. Not actively called anymore.
     */
    func checkValidity(context: NSManagedObjectContext) {
        let p = NSCompoundPredicate(orPredicateWithSubpredicates: [pInvalidLength, pInvalidData])
        let cdInvalidAttachments = CdAttachment.all(predicate: p, orderedBy: nil, in: context)
            as? [CdAttachment] ?? []
        if cdInvalidAttachments.count > 0 {
            logger.error("Still %d invalid attachments", cdInvalidAttachments.count)
        }
    }

    func fixAttachments(context: NSManagedObjectContext) {
        fixNilDataAttachments(context: context) { countFixedData in
            context.perform { [weak self] in
                let countFixedSize = self?.fixZeroSizeAttachments(context: context) ?? 0
                if countFixedData + countFixedSize > 0 {
                    context.saveAndLogErrors()
                }
                self?.markAsFinished()
            }
        }
    }

    public static func retrieveData(fromURL: URL?, block: @escaping ((Data?) -> Void)) {
        if let theURL = fromURL {
            do {
                let data = try Data(contentsOf: theURL)
                block(data)
                return
            } catch let err {
                Logger(category: Logger.backend).error("%@", err.localizedDescription)
            }
            let assets = PHAsset.fetchAssets(withALAssetURLs: [theURL], options: nil)
            if let theAsset = assets.firstObject {
                PHImageManager().requestImageData(for: theAsset, options: nil) {
                    data, string, orientation, options in
                    if let theData = data {
                        block(theData)
                    }
                }
            }
        } else {
            block(nil)
        }
    }
}
