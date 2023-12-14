//
//  VerifyIdentityViewController.swift
//  planckForiOS
//
//  Created by Martin Brude on 13/12/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import UIKit

class VerifyIdentityViewController: UIViewController {

    static let storyboardId = "VerifyIdentityViewController"

    @IBOutlet weak var verifyIdentityTitleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var trustwordsTitleLabel: UILabel!
    @IBOutlet weak var trustwordsLabel: UILabel!
    @IBOutlet weak var ownDeviceFingerprintsLabel: UILabel!
    @IBOutlet weak var ownDeviceUsernameLabel: UILabel!
    @IBOutlet weak var otherDeviceFingerprints: UILabel!
    @IBOutlet weak var otherDeviceUsernameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func trustwordsLanguageButtonPressed() {
        
    }
}

struct VerifyIdentityViewModel {
    
    public var title: String {
        return NSLocalizedString("Verify Identity", comment: "Verify Identity - Modal view title")
    }

    public var message: String {
        return NSLocalizedString("Ask your partner in person or over the phone: What are your Trustwords? Then compare the to the correct answer shown below", comment: "Instructions to verify Identity")
    }
    
    public var trustwordsTitle: String {
        return NSLocalizedString("Trustwords", comment: "Trustwords")
    }

    public var fingerprintsTitle: String {
        return NSLocalizedString("Fingerprints", comment: "Fingerprints")
    }
    
    public var closeButtonTitle: String {
        return NSLocalizedString("Close", comment: "Close button title")
    }
    
    var ownDeviceUsername: String {
        return ""
    }

    var ownDeviceTrustwords: String {
        return ""
    }
    
    var otherDeviceTrustwords: String {
        return ""
    }

    var otherDeviceUsername: String {
        return ""
    }

}
