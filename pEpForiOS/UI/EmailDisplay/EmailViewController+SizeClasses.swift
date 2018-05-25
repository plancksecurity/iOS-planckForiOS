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
            if (previousTraitCollection != nil) {
                adaptBarButtonItemsForAnyHeight()
            }
        }

    }

    private func adaptBarButtonItemsForAnyHeight() {
        guard let items = barItems, toolbarItems == nil else {
            return
        }

        setToolbarItems(items.reversed(), animated: true)
        navigationItem.setRightBarButtonItems([previousMessage, nextMessage], animated: true)
        self.navigationController?.setToolbarHidden(false, animated: true)

    }

    private func adaptBarButtonItemsForRegularSize() {
        guard let items = toolbarItems,
            let rightBarButtonItems = navigationItem.rightBarButtonItems  else {
                return
        }

        barItems = items

        navigationItem.rightBarButtonItems = items
        var leftBarButtonItems: [UIBarButtonItem] = []
        if let unwrappedLeftBarButtonItems = navigationItem.leftBarButtonItems {
            leftBarButtonItems.append(contentsOf: unwrappedLeftBarButtonItems)
        }
        leftBarButtonItems.append(contentsOf: rightBarButtonItems.reversed())

        navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)

    }
}

