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
    static let cidSchemeID = "security.pep.SecureWebViewController.setupSchemeHandler"

    /// Call this method once to let this class handle dic: URLs.
    ///
    /// - Parameter config: webview configuration to setup this handler for
    static func setup(config: WKWebViewConfiguration) {
        config.setURLSchemeHandler(CidHandler(), forURLScheme: cidSchemeID)
    }
}

@available(iOS, introduced: 11.0)
extension CidHandler: WKURLSchemeHandler {
    // MARK: - WKURLSchemeHandler

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {

    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }
}
