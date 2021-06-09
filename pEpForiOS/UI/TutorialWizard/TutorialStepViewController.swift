//
//  TutorialStepViewController.swift
//  pEp
//
//  Created by Martin Brude on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

// This class MUST be inherited. Do not use it directly.
// This is why we accept the default protected visibility.
class TutorialStepViewController: UIViewController {
    private var shouldUpdateLayoutDueRotation: Bool = false

    var tutorialTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        } else {
            return UIColor.black
        }
    }

    var left: NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        return paragraphStyle
    }

    var centered: NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }

    var centeredSpaced: NSMutableParagraphStyle {
        let paragraphStyle = centered
        paragraphStyle.lineSpacing = 6
        return paragraphStyle
    }

    var textAttributes: [NSAttributedString.Key : Any] {
        var style: NSParagraphStyle = centeredSpaced
        if UIDevice.isIphone && UIDevice.isLandscape {
            style = left
        } else if UIDevice.isIpadSmall {
            style = centered
        }

        var foregroundColor = UIColor(white: 24.0 / 255.0, alpha: 1.0)
        if #available(iOS 13.0, *) {
            foregroundColor = .secondaryLabel
        }
        return [
            .font: font,
            .foregroundColor: foregroundColor,
            .paragraphStyle: style
        ]
    }

    var font: UIFont {
        if UIDevice.isIpad {
            return UIFont.systemFont(ofSize: 20.0, weight: .regular)
        } else if UIDevice.isSmall {
            return UIFont.systemFont(ofSize: 11.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 14.0, weight: .regular)
    }
    
    var smallFont: UIFont {
        if UIDevice.isIpad {
            return UIFont.systemFont(ofSize: 11.0, weight: .regular)
        } else if UIDevice.isSmall {
            return UIFont.systemFont(ofSize: 9.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 10.0, weight: .regular)
    }
    

    var titleFont: UIFont {
        if UIDevice.isIpad {
            return UIFont.systemFont(ofSize: 42.0, weight: .regular)
        } else if UIDevice.isSmall {
            return UIFont.systemFont(ofSize: 18.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 28.0, weight: .regular)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldUpdateLayoutDueRotation {
            guard let superView = view.superview else {
                Log.shared.error("Superview is lost")
                return
            }
            superView.setNeedsLayout()
            superView.layoutIfNeeded()
            shouldUpdateLayoutDueRotation = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldUpdateLayoutDueRotation = true
    }

    /// Abstract method to be overriden
    /// This method MUST configure aspects of the layout of the view that can not be configured in storyboard.
    public func configureView() {
        Log.shared.errorAndCrash("This method must be overriden")
    }
}

extension TutorialStepViewController {
    struct Localized {
        // Step 0
        static let welcome = NSLocalizedString("Welcome to the p≡p Tutorial", comment: "Welcome to the p≡p Tutorial - Step 0")
        static let skipTutorial = NSLocalizedString("You can close this tutorial anytime with the Skip button.", comment: "Tutorial First text")
        static let privacyStatus = NSLocalizedString("p≡p uses a Privacy Status icon to indicate how secure your communication is.", comment: "Tutorial Second text")
        static let privacyStatusDescription = NSLocalizedString("This Privacy Status is shown as an icon the user´s avatars:", comment: "Tutorial Third text")
        static let topbar = NSLocalizedString("And in the top bar when you open or write an email:", comment: "Tutorial Fourth text")

        // Step 1
        static let secure = NSLocalizedString("Secure", comment: "Secure Label - Step 1")
        static let secureDescription = NSLocalizedString("With this Privacy Status all communication is Secure, but to confirm that your contact is really the person you know, you should compare Trustwords with this contact.", comment: "Secure Description Label - Step 1")
        static let secureAndTrustTitle = NSLocalizedString("Secure & Trusted", comment: "Secure & Trusted Label - Step 1")
        static let secureAndTrustedDescription = NSLocalizedString("When the Trustwords are confirmed to be correct and the Handshake is done, the communication will be completely secure and trusted", comment: "Secure & Trusted Description Label - Step 1")
        static let mistrusted = NSLocalizedString("Mistrusted", comment: "Mistrusted - Step 1")
        static let mistrustedDescription = NSLocalizedString("If the Trustwords are not correct, there could be an attack by a man‑in‑the‑middle.", comment: "Secure & Trusted Description Label - Step 1")

        // Step 2
        static let handshake = NSLocalizedString("Handshake", comment: "Title of the view")
        static let someTrustwords = NSLocalizedString("OUTDISTANCE   CORRINA   ETHIOPIA    OUTDRAW   FLEECER", comment: "Some trustwords")
        static let confirmButton = NSLocalizedString("Confirm", comment: "Confirm correct trustwords/PGP fingerprint")
        static let declineButton = NSLocalizedString("Decline", comment: "Incorrect trustwords/PGP fingerprint")
        static let privacyStatusIconExplanation = NSLocalizedString("When you click on the Privacy Status icon in the top bar, you will get to Handshake, where you can verify your communication partner.", comment: "Privacy status explanation Label")
        static let confirmTrustwordsExplanation = NSLocalizedString("When you confirm that the Trustwords of your communication partner are correct, your communication will be completely Secure & Trusted.", comment: "Confirm Trustwords explanation Label")

        // Step 3
        static let commonDenominator = NSLocalizedString("In this case the Privacy Status of the message is Secure, because this is the lowest common denominator of the two communication partners.", comment: "Privacy Status - Common Denominator Explanation")
        static let privacyStatusTitle = NSLocalizedString("Privacy Status", comment: "Privacy Status Label")
        static let privacyStatusExplanation = NSLocalizedString("The icon in the top bar reflects the Privacy Status of the message, which is the lowest common denominator of all communication partners of that message, for example:", comment: "Privacy Status Explanation")
    }
}

// MARK: - Trait Collection

extension TutorialStepViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                configureView()
                view.layoutIfNeeded()
            }
        }
    }

    func setBackgroundColor() {
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .light {
                view.backgroundColor = .white
            } else {
                view.backgroundColor = .secondarySystemBackground
            }
        } else {
            view.backgroundColor = .white
        }
    }
}
