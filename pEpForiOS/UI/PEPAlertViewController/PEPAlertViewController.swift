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
    private var _title: String?
    private var _message: String?
    private var _paintPEPInTitle = false
    private var _images: [UIImage]?
    private var _action = [PEPUIAlertAction]()

    static let storyboardId = "PEPAlertViewController"

    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        setUp(title: _title,
              paintPEPInTitle: _paintPEPInTitle,
              message: _message)

        setUp(images: _images)
        setUp(actions: _action)
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

            pEpAlertViewController._title = title
            pEpAlertViewController._paintPEPInTitle = paintPEPInTitle
            pEpAlertViewController._message = message
            pEpAlertViewController._images = image

            return pEpAlertViewController
    }

    func add(action: PEPUIAlertAction) {
        _action.append(action)
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
        alertImageView.animationDuration = 3.0
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
