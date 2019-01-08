//
//  PDFSecurityUITest.swift
//  pEpForiOSUITests
//
//  Created by Miguel Berrocal Gómez on 02/01/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import QuickLook

class PDFSecurityTest: XCTestCase {

    var pdfURL: URL!
    var loadUrlExpectation: XCTestExpectation!

    func testJavascriptDoesNotRunOnQuickLook() {
        let quickLook = QLPreviewController()
        quickLook.dataSource = self
        loadUrlExpectation = expectation()
        let bundle = Bundle(for: type(of: self))
        pdfURL = bundle.url(forResource: "javascript", withExtension: "pdf")
        let window = UIApplication.shared.windows[0]
        window.rootViewController?.present(quickLook, animated: true) {
            let delaySeconds = 5.0 //Needed so the page indicator disappears and we get a still screenshot
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                guard let data = self.getImageData(image: takeSnapshotOfView(view: quickLook.view)!) else {
                    XCTFail()
                    return
                }

                self.saveData(fileName: "screenshot", data: data)
                let expectedScreenshotUrl = bundle.url(forResource: "portraitExpected", withExtension: nil)!

                let expectedData = try! Data(contentsOf: expectedScreenshotUrl)

                let imagesAreTheSame = data == expectedData
                XCTAssertTrue(imagesAreTheSame)
                self.loadUrlExpectation.fulfill()
            }
        }
        wait(for: [loadUrlExpectation], timeout: 10)
    }

    func getImageData(image: UIImage) -> Data? {
        return UIImageJPEGRepresentation(image, 1)
    }

    func saveData(fileName: String, data: Data) {

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

    func saveImage(imageName: String, image: UIImage) {
        guard let data = UIImageJPEGRepresentation(image, 1) else { return }
        saveData(fileName: imageName, data: data)
    }


}

extension PDFSecurityTest: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return pdfURL as QLPreviewItem
    }
}

private func takeSnapshotOfView(view:UIView) -> UIImage? {
    UIGraphicsBeginImageContext(CGSize(width: view.frame.size.width, height: view.frame.size.height))
    view.drawHierarchy(in: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height), afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}
