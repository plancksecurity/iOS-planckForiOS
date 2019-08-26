//
//  PEPAlertViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class PEPAlertViewController: UIViewController {

    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var butonsStackView: UIStackView!

    private var viewModel: PEPAlertViewModelProtocol

    static let storyboardId = "PEPAlertViewController"

    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }

    static func fromStoryboard(title: String? = nil,
                     message: String? = nil,
                     paintPEPInTitle: Bool = false,
                     image: [UIImage]? = nil,
                     viewModel: PEPAlertViewModelProtocol = PEPAlertViewModel())
        -> PEPAlertViewController? {

            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let pEpAlertViewController = storyboard.instantiateViewController(
                withIdentifier: PEPAlertViewController.storyboardId) as? PEPAlertViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertViewController")
                    return nil
            }

            pEpAlertViewController.viewModel = viewModel
            pEpAlertViewController.viewModel.delegate = pEpAlertViewController

            setUp(alert: pEpAlertViewController,
                  title: title,
                  paintPEPInTitle: paintPEPInTitle,
                  message: message)

            setUp(alert: pEpAlertViewController,
                  images: image)

            return pEpAlertViewController
    }

    func add(action: PEPUIAlertAction) {
        let button = UIButton(type: .system)

        button.setTitle(action.title, for: .normal)
        button.setTitleColor(action.style, for: .normal)
        button.tag = viewModel.alertActionsCount
        button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
        viewModel.add(action: action)

        butonsStackView.addArrangedSubview(button)
    }
}

// MARK: - PEPAlertViewModelDelegate

extension PEPAlertViewController: PEPAlertViewModelDelegate {
    func dissmiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private

extension PEPAlertViewController {
    @objc private func didPress(sender: UIButton) {
        viewModel.handleButtonEvent(tag: sender.tag)
    }

    private static func setUp(alert: PEPAlertViewController, title: String?, paintPEPInTitle: Bool, message: String?) {
        alert.alertMessage.text = message

        if paintPEPInTitle {
            alert.alertTitle.attributedText = title?.paintPEPToPEPColour()
        } else {
            alert.alertTitle.text = title
        }
    }

    private static func setUp(alert: PEPAlertViewController, images: [UIImage]?) {
        alert.alertImageView.animationImages = images
        alert.alertImageView.animationDuration = 0.33
        alert.alertImageView.startAnimating()
    }
}
