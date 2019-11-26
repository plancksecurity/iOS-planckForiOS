//
//  ManualAccountSetupContainerView.swift
//  pEp
//
//  Created by Alejandro Gelos on 25/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class ManualAccountSetupContainerView: UIView {

    weak var manualAccountSetupView: ManualAccountSetupView?

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        guard let manualAccountSetupView = ManualAccountSetupView.loadViewFromNib() else {
            //Fail loading view, will show empty view and error handle on loadViewFromNib()
            return
        }

        addSubview(manualAccountSetupView)
        self.manualAccountSetupView = manualAccountSetupView

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
}
