//
//  PEPAlertViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class PEPAlertViewController: UIViewController {

    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var butonsStackView: UIStackView!

    private var _alertTitle: String?

    static let storyboardId = "PEPAlertViewController"


    private init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

    static func `init`(title: String? = nil,
                     message: String? = nil,
                     paintPEPInTitle: Bool = false,
                     image: [UIImage]? = nil) -> PEPAlertViewController? {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
        guard let pEpAlertViewController = storyboard.instantiateViewController(
            withIdentifier: PEPAlertViewController.storyboardId) as? PEPAlertViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertViewController")
                return nil
        }

        pEpAlertViewController._alertTitle = title
        pEpAlertViewController.alertMessage.text = message
        pEpAlertViewController.paint(greenPEPInTitle: paintPEPInTitle)

        return pEpAlertViewController
    }

    func add(action: PEPUIAlertAction) {
        let button = UIButton(type: .system)
        let ac = UIAlertAction(title: nil, style: .cancel, handler: nil)
//        button.state = 
    }
}


// MARK: - Private

extension PEPAlertViewController {
    private func paint(greenPEPInTitle: Bool) {
        if greenPEPInTitle {
            alertTitle.attributedText = alertTitle.text?.paintPEPToPEPColour()
        } else {
            alertTitle.text = _alertTitle
        }
    }
}
