//
//  ErrorBannerView.swift
//  pEp
//
//  Created by Martín Brude on 4/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit

class ErrorBannerView: UIView {
    private static let nibName = "ErrorBannerView"
    @IBOutlet weak var titleLabel: UILabel!

    private var errorLogToBeCopied: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setPEPFont(style: .body, weight: .regular)
    }

    /// Load the banner view.
    ///
    /// - Parameters:
    ///   - title: The title message to show
    /// - Returns: The view, if possible. If nil, something went wrong.
    static func loadViewFromNib(title: String) -> ErrorBannerView? {
        let nib = UINib(nibName: String(describing:self), bundle: nil)
        guard let errorBannerView =
            nib.instantiate(withOwner: nil, options: nil).first as? ErrorBannerView else {
                return nil
        }
        errorBannerView.titleLabel.text = title

        return errorBannerView
    }

}
