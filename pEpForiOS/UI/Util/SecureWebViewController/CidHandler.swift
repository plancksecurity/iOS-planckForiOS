//
//  CidHandler.swift
//  pEp
//
//  Created by Andreas Buff on 14.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit
import MessageModel

@available(iOS, introduced: 11.0)

/// WKURLSchemeHandler subclass to handle cid: URLs (images inlined in mails).
/// Provides content from MessageModel for a content IDs requested by a WKWebview instance.
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

@available(iOS, introduced: 11.0)
extension CidHandler: WKURLSchemeHandler {

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        defer {
            urlSchemeTask.didFinish()
        }
        //Check that the url path is of interest for you, etc...
        guard let url = urlSchemeTask.request.url else {
            Log.shared.errorAndCrash(component: #function, errorString: "No URL?")
            return
        }

        let urlResponse = URLResponse(url: url,
                                      mimeType: "image/*", //IOS-872: confirm wirldcard mimiType is working
                                      expectedContentLength: -1,
                                      textEncodingName: nil)
        urlSchemeTask.didReceive(urlResponse)

        // Get data
        guard let cid = url.absoluteString.extractCid() else {
            return
        }
        //TODO: change implementation to never use filename after IOS-872: is done
        /*
         - Get Attachment by CID
         - Create/get data of attachment
         - call urlSchemeTask.didReceive(data)
         */
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing todo.
        urlSchemeTask.didFinish()
    }
}
