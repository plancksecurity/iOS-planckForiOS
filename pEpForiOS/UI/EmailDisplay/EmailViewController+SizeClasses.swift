//
//  EmailViewController+SizeClasses.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 23/05/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension EmailViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if (traitCollection.horizontalSizeClass == .regular &&
            traitCollection.verticalSizeClass == .regular) {
            adaptBarButtonItemsForRegularSize()
        }
        else {
            adaptBarButtonItemsForAnyHeight()
        }
        
        self.tableView.updateSize()
    }

    private func adaptBarButtonItemsForAnyHeight() {
        guard let items = barItems, toolbarItems == nil else {
            return
        }

        setToolbarItems(items.reversed(), animated: true)
        navigationItem.setRightBarButtonItems([previousMessage, nextMessage], animated: true)
        self.navigationController?.setToolbarHidden(false, animated: false)
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

