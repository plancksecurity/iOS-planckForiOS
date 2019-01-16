//
//  ScreenshotTestUtil.swift
//  pEpForiOSTests
//
//  Created by Miguel Berrocal Gómez on 09/01/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class ScreenshotTestUtil {

    /// The maximum wait time for screenshot tests.
    static let waitTime: TimeInterval = 30

    static func getImageData(image: UIImage) -> Data? {
        return UIImageJPEGRepresentation(image, 1)
    }

    static func takeScreenshot(of view: UIView, after seconds:TimeInterval, name: String = "screenshot", completion: @escaping (Data?) -> () ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            guard let image = self.takeSnapshotOfView(view: view),
                let data = self.getImageData(image: image) else {
                    completion(nil)
                    return
            }
            self.saveData(fileName: name, data: data) //Used to debug or to update test image when non harmful UI changes happen
            completion(data)
        }
    }

    static func saveImage(imageName: String, image: UIImage) {
        guard let data = getImageData(image: image) else { return }
        saveData(fileName: imageName, data: data)
    }

    static func saveData(fileName: String, data: Data) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }
        }
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
    }

    static func takeSnapshotOfView(view:UIView) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: view.frame.size.width, height: view.frame.size.height))
        view.drawHierarchy(in: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
