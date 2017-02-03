//
//  FlagImageTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import UIKit

import pEpForiOS
import MessageModel

class FlagImageTests: XCTestCase {
    
    func testSimple() {
        let fi = FlagImages.create(imageSize: CGSize(width: 16, height: 16))

        XCTAssertNotNil(fi.notSeenImage)
        XCTAssertNotNil(fi.flaggedImage)
        XCTAssertNotNil(fi.flaggedAndNotSeenImage)

        let msg = Message.create(uuid: MessageID.generate())

        msg.imapFlags?.seen = true
        XCTAssertNil(fi.flagsImage(message: msg))

        msg.imapFlags?.flagged = true
        XCTAssertEqual(fi.flagsImage(message: msg), fi.flaggedImage)

        msg.imapFlags?.seen = false
        XCTAssertEqual(fi.flagsImage(message: msg), fi.flaggedAndNotSeenImage)

        msg.imapFlags?.flagged = false
        XCTAssertEqual(fi.flagsImage(message: msg), fi.notSeenImage)

        save(image: fi.flaggedImage, name: "flagged.png")
        save(image: fi.flaggedAndNotSeenImage, name: "flaggedAndNotSeenImage.png")
        save(image: fi.notSeenImage, name: "notSeenImage.png")
    }

    func getTargetDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func save(image: UIImage?, name: String) {
        if let img = image {
            if let data = UIImagePNGRepresentation(img) {
                let filename = getTargetDirectory().appendingPathComponent(name)
                print("filename \(filename)")
                try? data.write(to: filename)
            }
        }
    }
}
