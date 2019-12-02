//
//  ManualAccountSetupContainerView.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

// Did not crate a nested class for LoginScrollView, since its not visible from Interface builder

/// Use ONLY in storyboard, other inits are not implemented
final class ManualAccountSetupContainerView: UIView {
    /// Set ManualAccountSetupViewDelegate of ManualAccountSetupView.
    /// Used to handle envet from the ManualAccountSetupView
    weak var delegate: ManualAccountSetupViewDelegate? {
        didSet {
            //Nil case is handle in setupView getter
            setupView?.delegate = delegate
        }
    }

    /// Set TextFields delegate that are in ManualAccountSetupView.
    weak var textFieldsDelegate: UITextFieldDelegate? {
        didSet {
            //Nil case is handle in setupView getter
            setupView?.textFieldsDelegate = textFieldsDelegate
        }
    }

    /// Use this property to hide and show  pEpSync Switch inside ManualAccountSetupView
    var pEpSyncViewIsHidden = false {
        didSet {
            //Nil case is handle in setupView getter
            setupView?.pEpSyncView.isHidden = pEpSyncViewIsHidden
        }
    }

    /// /ManualAccountSetupView hold by the container.
    /// Should never be nil.  Nil case is handle in setupView getter, crash on debug and return nil in Prod
    var setupView: ManualAccountSetupView? {
        get {
            guard let setupView = _manualAccountSetupView else {
                Log.shared.errorAndCrash("Fail to get textFeilds from manualAccountSetupView")
                return nil
            }
            return setupView
        }
    }
    private weak var _manualAccountSetupView: ManualAccountSetupView?

    private init(){
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        guard let manualAccountSetupView = ManualAccountSetupView.loadViewFromNib() else {
            //Fail loading view, will show empty view and error handle on loadViewFromNib()
            return
        }

        addSubview(manualAccountSetupView)
        _manualAccountSetupView = manualAccountSetupView

        manualAccountSetupView.translatesAutoresizingMaskIntoConstraints = false

        manualAccountSetupView.layoutMarginsGuide.leadingAnchor.constraint(equalTo:
            layoutMarginsGuide.leadingAnchor).isActive = true
        manualAccountSetupView.layoutMarginsGuide.topAnchor.constraint(equalTo:
            layoutMarginsGuide.topAnchor).isActive = true
        manualAccountSetupView.layoutMarginsGuide.trailingAnchor.constraint(equalTo:
            layoutMarginsGuide.trailingAnchor).isActive = true
        manualAccountSetupView.layoutMarginsGuide.bottomAnchor.constraint(equalTo:
            layoutMarginsGuide.bottomAnchor).isActive = true
    }

    /// Return all the textFields subview of this view container. In this case
    func manualSetupViewTextFeilds() -> [UITextField] {
        guard let setupView = setupView else {
            //Error handle in setupView getter
            return []
        }
        return [setupView.firstTextField,
                setupView.secondTextField,
                setupView.thirdTextField,
                setupView.fourthTextField]
    }
}
