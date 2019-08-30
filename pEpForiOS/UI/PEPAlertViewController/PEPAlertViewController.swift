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
    @IBOutlet weak var buttonsView: UIView! {
        didSet {
            buttonsView.backgroundColor = .pEpGreyButtonLines
        }
    }

    private var viewModel: PEPAlertViewModelProtocol
    private var titleString: String?
    private var message: String?
    private var paintPEPInTitle = false
    private var images: [UIImage]?
    private var action = [PEPUIAlertAction]()

    static let storyboardId = "PEPAlertViewController"

    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        setUp(title: titleString,
              paintPEPInTitle: paintPEPInTitle,
              message: message)

        setUp(images: images)
        setUp(actions: action)
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

            pEpAlertViewController.titleString = title
            pEpAlertViewController.paintPEPInTitle = paintPEPInTitle
            pEpAlertViewController.message = message
            pEpAlertViewController.images = image

            return pEpAlertViewController
    }

    func add(action: PEPUIAlertAction) {
        self.action.append(action)
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

    private func setUp(title: String?, paintPEPInTitle: Bool, message: String?) {
        alertMessage.text = message

        if paintPEPInTitle {
            alertTitle.attributedText = title?.paintPEPToPEPColour()
        } else {
            alertTitle.text = title
        }
    }

    private func setUp(images: [UIImage]?) {
        alertImageView.animationImages = images
        alertImageView.animationDuration = 2.6
        alertImageView.startAnimating()
    }

    private func setUp(actions: [PEPUIAlertAction]) {
        actions.forEach { action in
            let button = UIButton(type: .system)

            button.setTitle(action.title, for: .normal)
            button.setTitleColor(action.style, for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 15)
            button.backgroundColor = .white
            button.tag = viewModel.alertActionsCount
            button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
            viewModel.add(action: action)

            butonsStackView.addArrangedSubview(button)
        }
    }
}
