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

    private var javascriptDataSource: PDFDatasource!
    private var nonJavascriptDataSource: PDFDatasource!
    private var bundle: Bundle!

    //Time to wait to take the screenshot, necessary as the pdf shows a page indicator that fades away.
    private let screenshotDelay = 5.0

    private let currentScreenshotFileName = "PDFTestScreenshot"
    private let expectedScreenshotFileName = "PDFExpectedScreenshot"


    override func setUp() {
        bundle = Bundle(for: type(of: self))
        let javascriptPDFUrl: URL! = bundle.url(forResource: "javascript", withExtension: "pdf")
        let nonJavascriptPDFUrl: URL! = bundle.url(forResource: "nojavascript", withExtension: "pdf")
        javascriptDataSource = PDFDatasource(url: javascriptPDFUrl)
        nonJavascriptDataSource = PDFDatasource(url: nonJavascriptPDFUrl)
    }

    func testJavascriptDoesNotRunOnQuickLook() {
        let screenShotsDidHappenExpectation = expectation(description: "Screenshots should happen")
        givenScreenshotsOfNonJavascriptAndJavascriptPDFs { (result) in
            switch result {
            case .failure(let reason):
                XCTFail(reason)
            case .success(result: let screenshots):
                let imagesAreTheSame = screenshots.0 == screenshots.1
                XCTAssertTrue(imagesAreTheSame)
                screenShotsDidHappenExpectation.fulfill()
            }
        }
        wait(for: [screenShotsDidHappenExpectation], timeout: ScreenshotTestUtil.waitTime)
    }

    //PRAGMA MARK: GIVEN

    private func givenAScreenshotOfQuicklookWithAJavascriptPDF(completion: @escaping (Result<Data>) -> ()) {
        let quickLook = givenAQuickLookLoadedWithAJavascriptPDF()
        screenshotOfViewControllerToPresent(viewController: quickLook, name: self.currentScreenshotFileName, completion: completion)
    }

    private func givenAScreenshotOfQuicklookWithANonJavascriptPDF(completion: @escaping (Result<Data>) -> ()) {
        let quickLook = givenAQuickLookLoadedWithANonJavascriptPDF()
        screenshotOfViewControllerToPresent(viewController: quickLook, name: self.expectedScreenshotFileName, completion: completion)
    }

    private func givenScreenshotsOfNonJavascriptAndJavascriptPDFs(completion: @escaping (Result<(Data,Data)>) -> ()) {
        givenAScreenshotOfQuicklookWithANonJavascriptPDF { (result) in
            switch result {
            case .failure(let reason):
                completion(.failure(reason))

            case .success(result: let nonJavascriptScreenshot):
                self.givenAScreenshotOfQuicklookWithAJavascriptPDF {(result) in
                    switch result {
                    case .failure(let reason):
                        completion(.failure(reason))
                    case .success(result: let javascriptScreenshot):
                        completion(.success(result: (nonJavascriptScreenshot, javascriptScreenshot)))
                    }
                }
            }
        }
    }

    private func screenshotOfViewControllerToPresent(viewController: UIViewController, name: String, completion: @escaping (Result<Data>) -> ()) {
        present(viewController: viewController) { (didSucceed) in
            guard didSucceed else {
                completion(.failure("Could not present viewController"))
                return
            }
            ScreenshotTestUtil.takeScreenshot(of: viewController.view, after: self.screenshotDelay, name: name) { maybeImageData in
                guard let imageData = maybeImageData else {
                    completion(.failure("There were problems creating the screenshot"))
                    return
                }
                viewController.dismiss(animated: true) {
                    completion(.success(result: imageData))
                }
            }
        }
    }

    private func givenAQuickLookLoadedWithAJavascriptPDF() -> QLPreviewController {
        return givenAQuickLookWith(dataSource: javascriptDataSource)

    }

    private func givenAQuickLookLoadedWithANonJavascriptPDF() -> QLPreviewController {
        return givenAQuickLookWith(dataSource: nonJavascriptDataSource)
    }

    private func givenAQuickLookWith(dataSource: QLPreviewControllerDataSource) -> QLPreviewController {
        let quickLook = QLPreviewController()
        quickLook.dataSource = dataSource
        return quickLook
    }

    //PRAGMA MARK: UTILS

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

    private enum Result<T> {
        case success(result: T)
        case failure(String)
    }

    private class PDFDatasource: QLPreviewControllerDataSource {

        class PreviewItem: NSObject, QLPreviewItem {

            let title: String
            let url: URL

            var previewItemTitle: String? {
                return title
            }

            var previewItemURL: URL? {
                return url
            }

            init(title: String, url: URL) {
                self.title = title
                self.url = url
            }
        }

        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return PreviewItem(title: "Test", url: url)
        }
    }
}
