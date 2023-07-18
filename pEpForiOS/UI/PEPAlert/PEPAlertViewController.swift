//
//  PlanckAlertViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

final class PlanckAlertViewController: UIViewController {
    public var alertStyle: AlertStyle = .default
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var keyInputView: KeyInputView!

    @IBOutlet weak private var alertImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak private var alertTitleTopViewHeightConstraint: NSLayoutConstraint!
    
    private var viewModel: PlanckAlertViewModelProtocol
    private var titleString: String?
    private var message: String?
    private var paintPEPInTitle = false
    private var images: [UIImage]?
    private var action = [PlanckUIAlertAction]()
    static let storyboardId = "PlanckAlertViewController"
    public var style : AlertStyle = .default

    required init?(coder aDecoder: NSCoder) {
        viewModel = PlanckAlertViewModel()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if UITraitCollection.current.userInterfaceStyle == .dark {
            keyInputView.backgroundColor = .secondarySystemBackground
        } else {
            keyInputView.backgroundColor = .systemBackground
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
                               viewModel: PlanckAlertViewModelProtocol = PlanckAlertViewModel()) -> PlanckAlertViewController? {
        let storyboard = UIStoryboard(name: Constants.reusableStoryboard, bundle: .main)
        guard let planckAlertViewController = storyboard.instantiateViewController(
            withIdentifier: PlanckAlertViewController.storyboardId) as? PlanckAlertViewController else {
            Log.shared.errorAndCrash("Fail to instantiateViewController PlanckAlertViewController")
            return nil
        }
        planckAlertViewController.viewModel = viewModel
        planckAlertViewController.viewModel.delegate = planckAlertViewController
        
        planckAlertViewController.titleString = title
        planckAlertViewController.paintPEPInTitle = paintPEPInTitle
        planckAlertViewController.message = message
        planckAlertViewController.images = image
        
        planckAlertViewController.modalPresentationStyle = .overFullScreen
        planckAlertViewController.modalTransitionStyle = .crossDissolve
        
        return planckAlertViewController
    }

    func add(action: PlanckUIAlertAction) {
        self.action.append(action)
    }
}

// MARK: - PlanckAlertViewModelDelegate

extension PlanckAlertViewController: PlanckAlertViewModelDelegate {
    func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - AlertStyle

extension PlanckAlertViewController {

    public enum AlertStyle : Int {
        case `default` = 0
        case warn = 1
        case undo = 2
    }

    public var primaryColor: UIColor {
        switch alertStyle {
        case .default:
            return .primary
        case .warn:
            return .pEpRed
        case .undo:
            return .primary
        }
    }

    public var secondaryColor: UIColor {
        switch alertStyle {
        case .default, .warn, .undo:
            return .secondaryLabel
        }
    }
}

// MARK: - Private

extension PlanckAlertViewController {

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
            alertTitle.attributedText = title?.paintPlanckToPlanckColour()
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

    private func setUp(alertType style: PlanckAlertViewModel.AlertType) {
        switch style {
        case .planckSyncWizard:
            alertImageView.contentMode = .scaleAspectFit
            alertTitleTopViewHeightConstraint.constant = ConstantsValues.alertTitleTopViewHeight
            alertImageViewHeightConstraint.constant = ConstantsValues.alertImageViewHeight
        case .planckDefault:
            break
        }
    }

    private func setUp(alertButton: UIButton, style: PlanckAlertViewModel.AlertType) {
        switch style {
        case .planckSyncWizard:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .body, weight: .semibold)
        case .planckDefault:
            alertButton.titleLabel?.font = UIFont.pepFont(style: .callout, weight: .semibold)
            break
        }
    }

    private func setUp(actions: [PlanckUIAlertAction]) {
        actions.forEach { action in
            let button = UIButton(type: .system)

            button.setTitle(action.title, for: .normal)
            button.accessibilityIdentifier = action.title
            button.setTitleColor(action.style, for: .normal)
            setUp(alertButton: button, style: viewModel.alertType)

            if UITraitCollection.current.userInterfaceStyle == .dark {
                button.backgroundColor = .secondarySystemBackground
            } else {
                button.backgroundColor = .systemBackground
            }
            button.tag = viewModel.alertActionsCount
            button.addTarget(self, action: #selector(didPress(sender:)), for: .touchUpInside)
            viewModel.add(action: action)
            buttonsStackView.addArrangedSubview(button)
        }
    }
}

// MARK: - Trait Collection

extension PlanckAlertViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let thePreviousTraitCollection = previousTraitCollection else {
            // Valid case: optional value from Apple.
            return
        }

        if thePreviousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection) {
            view.layoutIfNeeded()
        }
    }
}
