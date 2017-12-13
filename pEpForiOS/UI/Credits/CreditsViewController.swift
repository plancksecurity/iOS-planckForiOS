//
//  CreditsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import WebKit

class CreditsViewController: UIViewController {

    var webView: WKWebView!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadHTMLString(html(), baseURL: nil)
    }

    // Due to an Apple bug (https://bugs.webkit.org/show_bug.cgi?id=137160),
    // WKWebView has to be created programatically when supporting iOS versions < iOS11.
    // This implementation is taken over from the Apple docs:
    // https://developer.apple.com/documentation/webkit/wkwebview#2560973
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }

    // MARK: - Other

    private func html() -> String {
        let appVersion = InfoPlist.versionDisplayString() ?? "666"
        let backgroundColor = UIColor.hexPEpLightBackground
        let fontColor = UIColor.hexPEpGray
        let fontSize = "28"
        let fontFamily = "Helvetica Neue"
        let fontWeight = "500"
        let styleP = "p {color: \(fontColor);font-size: \(fontSize)px;font-family: \(fontFamily);font-weight: \(fontWeight);}"
        let styleBody = "body {background-color: \(backgroundColor);}"
        let styleA = "a {color: \(fontColor);font-size: \(fontSize)px;font-family: \(fontFamily);font-weight: \(fontWeight);}"
        let styleColumn = ".column {float: left;margin: -15px 0px -20px 0px;font-size: \(fontSize)px;font-family: \(fontFamily);font-weight: \(fontWeight);}.left {width: 25%;}.right {width: 75%;}.row:after {content: \"\";display: table;clear: both;}"
        let style = "<style>\(styleP)\(styleBody)\(styleColumn)\(styleA)</style>"
        let result = """
        <html> <head> \(style)

        </head>
        <body>
        <blockquote>
        <p>&nbsp;</p>
        <p>p&equiv;p for iOS<br/> \(appVersion)</p>
        <p>Credits:<br />
            Volker Birk, Sandro K&ouml;chle, Sabrina Schleifer, Robert Goldmann, Rena Tangens, Patricia Bednar, Patrick Meier, padeluun, Nana Karlstetter, Meinhard Starostik, Mathijs de Haan, Martin Vojcik, Markus Schaber, Lix, Leonard Marquitan, Leon Schumacher, Lars Rohwedder, Krista Bennet, Kinga Prettenhoffer, Hussein Kasem, Hern&acirc;ni Marques, Dol&ccedil;a Moreno, Dirk Zimmermann, Xavier Algarra Torello, Andreas Buff, Andreas, Dietz Proepper, Detlev Sieber, Dean, Daniel Sosa, be, Berna Alp, Bart Polot, Andy Weber, Ana Rebolledo
        </p>
        <p>&nbsp;</p>
        <p>Thanks to:
        \(thanxRows())
        </p>
        </blockquote>
        </body>
        </html>
"""
        return result
    }

    private func thanxRows() -> String {
        let names = ["GPG4Win",
                     "pEpEngine",
                     "GPGME",
                     "LibGPG-error",
                     "Libcrypt",
                     "Libassuan",
                     "Libksba",
                     "GNUPG",
                     "Libcurl",
                     "Libiconv",
                     "LibEtPan",
                     "MimeKitLite"]
        let links = ["https://www.gpg4win.org/",
                     "https://cacert.pep.foundation/dev/repos/pEpEngine/",
                     "https://www.gnupg.org/software/gpgme/",
                     "https://gnupg.org/related_software/libgpg-error/",
                     "https://directory.fsf.org/wiki/Libgpgcrypt",
                     "https://gnupg.org/related_software/libassuan/",
                     "https://gnupg.org/related_software/libksba/",
                     "https://gnupg.org/",
                     "https://curl.haxx.se/libcurl/",
                     "https://www.gnu.org/software/libiconv/",
                     "https://www.etpan.org/libetpan.html",
                     "https://www.mimekit.net/"]
        var htmlThanx = ""
        for (i, name) in names.enumerated() {
            let link = links[i]
            var row = "<div class=\"row\">"
            row += "<div class=\"column left\">"
            row += "<p>\(name)</p>"
            row += "</div>"
            row += "<div class=\"column right\">"
            row += "<p><a href=\"\(link)\"</a> \(link)</p>"
            row += "</div>"
            row += "</div> "
            htmlThanx += row
        }

        return htmlThanx
    }
}

// MARK: - WKUIDelegate

extension CreditsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .other:
            // We are initially loading our own HTML
            decisionHandler(.allow)
            return
        case .linkActivated:
            // Open clicked links in Safari
            guard let newURL = navigationAction.request.url, UIApplication.shared.canOpenURL(newURL)
                else {
                    break
            }
            UIApplication.shared.openURL(newURL)
        case .backForward: fallthrough
        case .formResubmitted: fallthrough
        case .formSubmitted: fallthrough
        case .reload:
            break
        }
        decisionHandler(.cancel)
    }
}
