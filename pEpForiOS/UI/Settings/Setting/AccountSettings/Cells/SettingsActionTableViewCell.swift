//
//  SettingsActionTableViewCell.swift
//  planckForiOS
//
//  Created by Martin Brude on 18/7/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit

class SettingsActionTableViewCell: UITableViewCell {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    public var activityIndicatorIsOn = false {
        didSet {
            if activityIndicatorIsOn {
                startActivityIndicator()
            } else {
                stopActivityIndicator()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .medium
        activityIndicator.isHidden = !activityIndicatorIsOn
    }

    public func startActivityIndicator() {
        activityIndicator.startAnimating()
    }

    public func stopActivityIndicator() {
        activityIndicator.stopAnimating()
    }
}
