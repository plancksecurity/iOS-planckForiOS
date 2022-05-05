//
//  ErrorBannerView.swift
//  pEp
//
//  Created by Martín Brude on 4/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class ErrorBannerView: UIView {
    static let nibName = "ErrorBannerView"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var copyLogButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!

    private var log: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setPEPFont(style: .footnote, weight: .regular)
        titleLabel.text = NSLocalizedString("Server Unreachable", comment: "Server Unreachable title")
        subtitleLabel.setPEPFont(style: .footnote, weight: .regular)
        subtitleLabel.text = NSLocalizedString("We could not connect to the SMTP server", comment: "Server Unreachable description")
        copyLogButton.setTitleColor(.white, for: .highlighted)
    }

    static func loadViewFromNib(log: String) -> ErrorBannerView? {
        let nib = UINib(nibName: String(describing:self), bundle: nil)
        guard let errorBannerView =
            nib.instantiate(withOwner: nil, options: nil).first as? ErrorBannerView else {
                Log.shared.errorAndCrash("Fail to load ErrorBannerView from xib")
                return nil
        }
        errorBannerView.log = log
        return errorBannerView
    }

    @IBAction func buttonPressed() {
        UIPasteboard.general.string = log
    }

    @IBAction func closeButtonPressed() {
        removeFromSuperview()
    }
}
