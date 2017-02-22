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
 Downloads attachment content with nil data, also fixes nil sizes.
 */
open class FixAttachmentsOperation: ConcurrentBaseOperation {
    var openFetchCount = 0

    override open func main() {
        privateMOC.perform {
            self.doTheWork()
        }
    }

    func doTheWork() {
        let p1 = NSPredicate(format: "length = 0")
        guard let cdAttachments1 = CdAttachment.all(predicate: p1, orderedBy: nil, in: privateMOC)
            as? [CdAttachment] else {
                markAsFinished()
                return
        }
        for cdAttach in cdAttachments1 {
            if let theData = cdAttach.data {
                cdAttach.length = Int64(theData.length)
                Record.saveAndWait(context: privateMOC)
            }
        }

        let p2 = NSPredicate(format: "data = nil")
        guard let cdAttachments2 = CdAttachment.all(predicate: p2, orderedBy: nil, in: privateMOC)
            as? [CdAttachment] else {
                markAsFinished()
                return
        }
        openFetchCount = cdAttachments2.count
        for cdAttach in cdAttachments2 {
            if let urlString = cdAttach.url, let theURL = URL(string: urlString) {
                FixAttachmentsOperation.retrieveData(fromURL: theURL) { data in
                    if let theData = data {
                        self.privateMOC.performAndWait {
                            cdAttach.data = theData as NSData
                            Record.saveAndWait(context: self.privateMOC)
                            if self.openFetchCount == 0 {
                                self.markAsFinished()
                            }
                        }
                    }
                }
            } else {
                Log.error(component: comp, errorString: "CdAttachment with invalid URL")
                openFetchCount -= 1
            }
        }
        if openFetchCount == 0 {
            markAsFinished()
        }
    }

    public static func retrieveData(fromURL: URL?, block: @escaping ((Data?) -> Void)) {
        if let theURL = fromURL {
            do {
                let data = try Data(contentsOf: theURL)
                block(data)
            } catch {}

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
