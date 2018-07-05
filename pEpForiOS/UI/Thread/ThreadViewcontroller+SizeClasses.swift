//
//  ThreadedViewcontroller+SizeClasses.swift
//  pEp
//
//  Created by Borja González de Pablo on 27/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension ThreadViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if (traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular) {
            adaptBarButtonItemsForRegularSize()
        }
    }
    private func adaptBarButtonItemsForRegularSize() {
        guard let items = toolbarItems else {
            return
        }

        barItems = items

        navigationItem.rightBarButtonItems = items
        self.navigationController?.setToolbarHidden(true, animated: false)
        toolbarItems = nil
    }
}
