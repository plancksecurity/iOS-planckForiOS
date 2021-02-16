//
//  String+PEPSignature.swift
//  pEp
//
//  Created by Alejandro Gelos on 17/07/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

extension String {
    public static var pepSignature: String {
        return NSLocalizedString("sent with p≡p",
                                 comment: "pEp mail signature. Newlines will be added by app")
    }

    public static var pEpSignatureHtml: String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()
        return "<a href=\"https://pep.software\" style=\"color:\(UIColor.pEpDarkGreenHex); text-decoration: none;\">\(pEpSignatureTrimmed)</a>"
    }

    public func replacingOccurrencesOfPepSignatureWithHtmlVersion() -> String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()

        var result = replacingOccurrences(of: pEpSignatureTrimmed, with: String.pEpSignatureHtml)

        // The signature comes in different formats here for some reason. Search & replace all known versions
        let strangePEPSignaturePatterns = [#"<p class=\"[\S][\S]\"><span class=\"[\S][\S]\">sent with p<\/span><span class=\"[\S][\S]\">≡<\/span><span class=\"[\S][\S]\">p<\/span><\/p>"#,
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
                                                                       withTemplate: String.pEpSignatureHtml)
        }
        return result
    }
}
