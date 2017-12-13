//
//  CreditsViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import WebKit

class CreditsViewController: UIViewController, WKUIDelegate {

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
        webView.uiDelegate = self
        view = webView
    }

    // MARK: - Other

    private func html() -> String {
        return
            """
<blockquote>
        <p><span style=\"color: #333333;\">p&equiv;p for iOS</span><br /><span style=\"color: #333333;\"> Version: $current_app_version</span></p>
        <p><span style=\"color: #333333;\">Credits:</span><br /><span style=\"color: #333333;\"> Volker Birk, Sandro K&ouml;chle, Sabrina Schleifer, Robert Goldmann, Rena Tangens, Patricia Bednar, Patrick Meier, padeluun, Nana Karlstetter, Meinhard Starostik, Mathijs de Haan, Martin Vojcik, Markus Schaber, Lix, Leonard Marquitan, Leon Schumacher, Lars Rohwedder, Krista Bennet, Kinga Prettenhoffer, Hussein Kasem, Hern&acirc;ni Marques, Dol&ccedil;a Moreno, Dirk Zimmermann, Xavier Algarra Torello, Andreas Buff, Andreas, Dietz Proepper, Detlev Sieber, Dean, Daniel Sosa, be, Berna Alp, Bart Polot, Andy Weber, Ana Rebolledo</span></p>
        <p><span style=\"color: #333333;\">Thanks to:</span><br /><span style=\"color: #333333;\"> GPG4Win <a class=\"external-link\" style=\"color: #333333;\" href=\"https://www.gpg4win.org/\" rel=\"nofollow\">https://www.gpg4win.org/</a></span><br /><span style=\"color: #333333;\"> pEpEngine <a class=\"external-link\" style=\"color: #333333;\" href=\"https://cacert.pep.foundation/dev/repos/pEpEngine/\" rel=\"nofollow\">https://cacert.pep.foundation/dev/repos/pEpEngine/</a></span><br /><span style=\"color: #333333;\"> GPGME <a class=\"external-link\" style=\"color: #333333;\" href=\"https://gnupeg.org/related_software/gpgme/index.html\" rel=\"nofollow\">https://gnupeg.org/related_software/gpgme/index.html</a></span><br /><span style=\"color: #333333;\"> LibGPG-error <a class=\"external-link\" style=\"color: #333333;\" href=\"https://gnupg.org/related_software/libgpg-error/index.html\" rel=\"nofollow\">https://gnupg.org/related_software/libgpg-error/index.html</a></span><br /><span style=\"color: #333333;\"> Libcrypt <a class=\"external-link\" style=\"color: #333333;\" href=\"https://directory.fsf.org/wiki/Libgpgcrypt\" rel=\"nofollow\">https://directory.fsf.org/wiki/Libgpgcrypt</a></span><br /><span style=\"color: #333333;\"> Libassuan <a class=\"external-link\" style=\"color: #333333;\" href=\"https://gnupg.org/related_software/libassuan/index.html\" rel=\"nofollow\">https://gnupg.org/related_software/libassuan/index.html</a></span><br /><span style=\"color: #333333;\"> Libksba <a class=\"external-link\" style=\"color: #333333;\" href=\"https://gnupg.org/related_software/libksba/index.html\" rel=\"nofollow\">https://gnupg.org/related_software/libksba/index.html</a></span><br /><span style=\"color: #333333;\"> GNUPG <a class=\"external-link\" style=\"color: #333333;\" href=\"https://gnupg.org/\" rel=\"nofollow\">https://gnupg.org/</a></span><br /><span style=\"color: #333333;\"> Libcurl <a class=\"external-link\" style=\"color: #333333;\" href=\"https://curl.haxx.se/libcurl/\" rel=\"nofollow\">https://curl.haxx.se/libcurl/</a></span><br /><span style=\"color: #333333;\"> Libiconv <a class=\"external-link\" style=\"color: #333333;\" href=\"https://www.gnu.org/software/libiconv/\" rel=\"nofollow\">https://www.gnu.org/software/libiconv/</a></span><br /><span style=\"color: #333333;\"> LibEtPan <a class=\"external-link\" style=\"color: #333333;\" href=\"https://www.etpan.org/libetpan.html\" rel=\"nofollow\">https://www.etpan.org/libetpan.html</a></span><br /><span style=\"color: #333333;\"> MimeKitLite <a class=\"external-link\" style=\"color: #333333;\" href=\"https://www.mimekit.net/\" rel=\"nofollow\">https://www.mimekit.net/</a></span></p>
        </blockquote>
"""
    }


}
