//
//  String+PEPSignature.swift
//  pEp
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import UIKit

extension String {
    public static var planckSignature: String {
        return NSLocalizedString("sent with planck",
                                 comment: "planck mail signature. Newlines will be added by app")
    }

    public static var planckSignatureHtml: String {
        let pEpSignatureTrimmed = String.planckSignature.trimmed()
        let hex = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor.primaryHexDarkMode : UIColor.primaryHexLightMode
        return "<a href=\"https://planck.security\" style=\"color:\(hex); text-decoration: none;\">\(pEpSignatureTrimmed)</a>"
    }

    public func replacingOccurrencesOfPepSignatureWithHtmlVersion() -> String {
        let pEpSignatureTrimmed = String.planckSignature.trimmed()

        var result = replacingOccurrences(of: pEpSignatureTrimmed, with: String.planckSignatureHtml)

        // The signature comes in different formats here for some reason. Search & replace all known versions
        let strangePEPSignaturePatterns = [#"<p class=\"[\S][\S]\"><span class=\"[\S][\S]\">sent with planck<\/span><\/p>"#,
                                           #"<p class=\"p2\"><span class=\"s2\">sent with p&#x2261;p</span></p>"#]
        for strangePEPSignaturePattern in strangePEPSignaturePatterns {
            guard let strangePEPSignatureRegex = try? NSRegularExpression(pattern: strangePEPSignaturePattern,
                                                                          options: [])
            else {
                return result
            }
            result = strangePEPSignatureRegex.stringByReplacingMatches(in: result,
                                                                       options: [],
                                                                       range: result.wholeRange(),
                                                                       withTemplate: String.planckSignatureHtml)
        }
        return result
    }
}
