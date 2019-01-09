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

class SecurePDFScreenshotTest: XCTestCase {

    private enum Result<T> {
        case success(result: T)
        case failure()
    }

    var pdfURL: URL!
    var bundle: Bundle!

    //Time to wait to take the screenshot, necessary as the pdf shows a page indicator that fades away.
    let screenshotDelay = 5.0
    let currentScreenshotName = "PDFTestScreenshot"

    override func setUp() {
        bundle = Bundle(for: type(of: self))
        pdfURL = bundle.url(forResource: "javascript", withExtension: "pdf")
    }

    //Test should be done with iPhone SE Simulator.
    func testJavascriptDoesNotRunOnQuickLook() {
        let screenShotExpectation = expectation()
        givenAScreenshotOfQuicklookWithAJavascriptPDF { (result) in
            switch result {
            case .failure():
                XCTFail("could not load quicklook")
            case .success(result: let imageData):

                guard let expectedImageData = self.getBundleImageDataFor(name: "portraitExpected") else {
                    XCTFail("expected image not in bundle")
                    return
                }

                let areImagesTheSame = imageData == expectedImageData
                XCTAssertTrue(areImagesTheSame)
                screenShotExpectation.fulfill()
            }
        }
        wait(for: [screenShotExpectation], timeout: UnitTestUtils.asyncWaitTime)
    }

    //PRAGMA MARK: GIVEN

    private func givenAScreenshotOfQuicklookWithAJavascriptPDF(completion: @escaping (Result<Data>) -> ()) {
        let quickLook = givenAQuickLookLoadedWithJavascriptPDF()
        present(viewController: quickLook) { (didSucceed) in
            guard didSucceed else {
                completion(.failure())
                return
            }
            ScreenshotTestUtil.takeScreenshot(of: quickLook.view, after: self.screenshotDelay, name: self.currentScreenshotName) { maybeImageData in
                guard let imageData = maybeImageData else {
                    completion(.failure())
                    return
                }
                completion(.success(result: imageData))
            }
        }
    }

    private func givenAQuickLookLoadedWithJavascriptPDF() -> QLPreviewController {
        let quickLook = QLPreviewController()
        quickLook.dataSource = self
        return quickLook
    }

    //PRAGMA MARK: INSTANCE UTILS

    private func present(viewController: UIViewController, completion: ((Bool) -> ())? = nil) {
        var didSucceed = false
        let windows = UIApplication.shared.windows
        guard windows.count > 0, let rootViewController = windows[0].rootViewController else {
            completion?(didSucceed)
            return
        }
        rootViewController.present(viewController, animated: true) {
            didSucceed = true
            completion?(didSucceed)
        }
    }

    private func getBundleImageDataFor(name:String) -> Data? {
        let url = bundle.url(forResource: name, withExtension: nil)!
        return try? Data(contentsOf: url)
    }
}

extension SecurePDFScreenshotTest: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return pdfURL as QLPreviewItem
    }
}
