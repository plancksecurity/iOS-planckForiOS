//
//  PEPAlertViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

final class PEPAlertViewController: UIViewController {
    public var alertStyle: AlertStyle = .default
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var keyInputView: KeyInputView!


    @IBOutlet weak private var alertImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak private var alertTitleTopViewHeightConstraint: NSLayoutConstraint!
    
    private var viewModel: PEPAlertViewModelProtocol
    private var titleString: String?
    private var message: String?
    private var paintPEPInTitle = false
    private var images: [UIImage]?
    private var action = [PEPUIAlertAction]()
    static let storyboardId = "PEPAlertViewController"
    public var style : AlertStyle = .default
    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPAlertViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            if UITraitCollection.current.userInterfaceStyle == .dark {
                keyInputView.backgroundColor = .secondarySystemBackground
            } else {
                keyInputView.backgroundColor = .systemBackground
            }
        } else {
            keyInputView.backgroundColor = .white
        }
        setUp(title: titleString,
              paintPEPInTitle: paintPEPInTitle,
              message: message)

        setUp(images: images)
        setUp(alertType: viewModel.alertType)
        setUp(actions: action)
    }

    static func fromStoryboard(title: String? = nil,
                     message: String? = nil,
                     paintPEPInTitle: Bool = false,
                     image: [UIImage]? = nil,
                     viewModel: PEPAlertViewModelProtocol = PEPAlertViewModel())
        -> PEPAlertViewController? {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: .main)
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

        pEpAlertViewController.modalPresentationStyle = .overFullScreen
        pEpAlertViewController.modalTransitionStyle = .crossDissolve

        return pEpAlertViewController
    }

    func add(action: PEPUIAlertAction) {
        self.action.append(action)
    }
}

// MARK: - PEPAlertViewModelDelegate

extension PEPAlertViewController: PEPAlertViewModelDelegate {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - AlertStyle

extension PEPAlertViewController {

    public enum AlertStyle : Int {
        case `default` = 0
        case warn = 1
        case undo = 2
    }

    public var primaryColor: UIColor {
        switch alertStyle {
        case .default:
            return .pEpGreen
        case .warn:
            return .pEpRed
        case .undo:
            if #available(iOS 13.0, *) {
                return .label
            } else {
                return .pEpBlack
            }
        }
    }

    public var secondaryColor: UIColor {
        switch alertStyle {
        case .default, .warn, .undo:
            if #available(iOS 13.0, *) {
                return .secondaryLabel
            } else {
                return .pEpBlack
            }
        }
    }
}

// MARK: - Private

extension PEPAlertViewController {

    private struct ConstantsValues {
        static let alertTitleTopViewHeight: CGFloat = 0 // Set empty not important view invisible (in this case)
        static let alertImageViewHeight: CGFloat = 100 // Each image should have the same height
    }

    @objc private func didPress(sender: UIButton) {
        viewModel.handleButtonEvent(tag: sender.tag)
    }

    private func setUp(title: String?, paintPEPInTitle: Bool, message: String?) {
        alertMessage.text = message
        alertMessage.font = UIFont.pepFont(style: .footnote, weight: .regular)
        alertTitle.font = UIFont.pepFont(style: .body, weight: .semibold)
        if paintPEPInTitle {
            alertTitle.attributedText = title?.paintPEPToPEPColour()
        } else {
            alertTitle.text = title
        }
    }

    private func setUp(images: [UIImage]?) {
        guard let images = images else {
            alertImageView.removeFromSuperview()
            return
        }
        alertImageView.animationImages = images
        alertImageView.animationDuration = 2.6
        alertImageView.startAnimating()
    }

    private func setUp(alertType style: PEPAlertViewModel.AlertType) {
        switch style {
        case .pEpSyncWizard:
            alertImageView.contentMode = .scaleAspectFit
            alertTitleTopViewHeightConstraint.constant = ConstantsValues.alertTitleTopViewHeight
            alertImageViewHeightConstraint.constant = ConstantsValues.alertImageViewHeight
        case .pEpDefault:
            break
        }
    }

    private func setUp(alertButton: UIButton, style: PEPAlertViewModel.AlertType) {
        switch style {
        case .pEpSyncWizard:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .body, weight: .semibold)
        case .pEpDefault:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .callout, weight: .semibold)
            break
        }
    }

    private func setUp(actions: [PEPUIAlertAction]) {
        actions.forEach { action in
            let button = UIButton(type: .system)

            button.setTitle(action.title, for: .normal)
            button.setTitleColor(action.style, for: .normal)
            setUp(alertButton: button, style: viewModel.alertType)

            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .systemBackground
                }
            } else {
                button.backgroundColor = .white
            }
            button.tag = viewModel.alertActionsCount
            button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
            viewModel.add(action: action)
            buttonsStackView.addArrangedSubview(button)
        }
    }
}

// MARK: - Trait Collection

extension PEPAlertViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if #available(iOS 13.0, *) {
            if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
                view.layoutIfNeeded()
            }
        }
    }
}
