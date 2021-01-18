//
//  CidHandler.swift
//  pEp
//
//  Created by Andreas Buff on 14.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit
import MessageModel
import pEpIOSToolbox

/// WKURLSchemeHandler subclass to handle cid: URLs (images inlined in mails).
/// Provides content from the store for a content IDs requested by a WKWebview instance.
class CidHandler : NSObject {
    static let urlScheme = "cid"

    /// Call this method once to let this class handle "cid:" URLs.
    ///
    /// - Parameter config: webview configuration to setup this handler for
    static func setup(config: WKWebViewConfiguration) {
        config.setURLSchemeHandler(CidHandler(), forURLScheme: urlScheme)
    }
}

// MARK: - WKURLSchemeHandler

extension CidHandler: WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        defer {
            // Let WkWebview know we are done
            urlSchemeTask.didFinish()
        }
        guard let url = urlSchemeTask.request.url else {
            Log.shared.errorAndCrash("No URL?")
            return
        }

        let urlResponse = URLResponse(url: url,
                                      mimeType: "image/*",
                                      expectedContentLength: -1,
                                      textEncodingName: nil)
        // Let WkWebview know we have started
        urlSchemeTask.didReceive(urlResponse)

        // Get the requested data from the store
        guard let cid = url.absoluteString.extractCid() else {
            return
        }
        let attachment = Attachment.by(cid: cid)
        guard let data = attachment?.data else {
            return
        }
        // Pass the requested data to WkWebview
        urlSchemeTask.didReceive(data)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing todo.
        urlSchemeTask.didFinish()
    }
}
