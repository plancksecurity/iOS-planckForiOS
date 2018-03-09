//
//  WebViewNoJS.swift
//  pEp
//
//  Created by Andreas Buff on 09.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import WebKit

class SecureWebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard !webView.configuration.preferences.javaScriptEnabled else {
            Log.shared.errorAndCrash(component: #function, errorString: "JS must be disabled")
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configuration = configJSDisabled()
    }

    private func preferencesJSDisabled() -> WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = false
    }

    private func configJSDisabled() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.preferences = preferencesJSDisabled()

        return config
    }
}
