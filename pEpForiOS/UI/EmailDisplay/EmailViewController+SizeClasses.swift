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

        if ( traitCollection.horizontalSizeClass == .regular ||
            (traitCollection.horizontalSizeClass == .regular &&
                traitCollection.verticalSizeClass == .regular) ) {
            adaptBarButtonItemsForRegularSize()
        }
        else {
            adaptBarButtonItemsForAnyHeight()
        }

    }

   private func adaptBarButtonItemsForAnyHeight() {
        guard let items = barItems, toolbarItems == nil else {
            return
        }

        let backButton = navigationItem.backBarButtonItem
        let leftBarButtonItems = self.navigationItem.leftBarButtonItems

//        self.navigationItem.leftBarButtonItems = nil
        self.navigationItem.rightBarButtonItems = [nextMessage, previousMessage]

        self.navigationController?.setToolbarHidden(false, animated: true)
        self.setToolbarItems(items, animated: true)
    }

    private func adaptBarButtonItemsForRegularSize() {
        guard let items = barItems else {
            return
        }

        let backButton = navigationItem.backBarButtonItem
        let leftBarButtonItems = self.navigationItem.leftBarButtonItems

        self.navigationItem.rightBarButtonItems = items.reversed()
//        self.navigationItem.leftBarButtonItem = nil
//        self.navigationItem.leftBarButtonItems = [previousMessage, nextMessage]

        if let backButton = backButton {
            self.navigationItem.leftBarButtonItems?.append(backButton)
        }

        self.navigationController?.setToolbarHidden(true, animated: true)
        self.toolbarItems = nil
    }
}

