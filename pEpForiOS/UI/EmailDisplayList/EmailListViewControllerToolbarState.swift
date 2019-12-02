//
//  EmailListViewControllerToolbarState.swift
//  pEp
//
//  Created by Dirk Zimmermann on 02.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

/// The possible, toolbar-relevant states of the email list view, that is
/// the states concerning the master toolbar.
struct EmailListViewControllerToolbarState {
    /// The (original) toolbar items from storyboard.
    var storyboardToolbarItems = [UIBarButtonItem]()

    /// Should the unflag button be shown?
    var showUnflagButton: Bool

    /// Should the show unread button currently be shown?
    var showUnreadButton: Bool

    /// Should the pEp logo (with a link to the settings) be shown?
    var showPepButtonInMaster: Bool

    /// When this is true, the view is in the mode for editing messages.
    /// This sort of overrides other states.
    var showEditToolbar: Bool
}

extension EmailListViewControllerToolbarState {
    init() {
        self.showUnflagButton = false
        self.showUnreadButton = false
        self.showPepButtonInMaster = true
        self.showEditToolbar = false
    }
}
