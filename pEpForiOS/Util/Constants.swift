//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

extension Constants {
    /** Settings key for storing the email of the last used account */
    static let kSettingLastAccountEmail = "kSettingLastAccountEmail"

    static let defaultFileName = NSLocalizedString("unnamed",
                                                   comment:
        "file name used for unnamed attachments")

    /// Storyboard ID to instantiate ComposeViewController
    /// Is not in ComposeViewController.swift as it is the ID of the NavigationController that
    /// holds the ViewController, which the ViewController has no knowledge of.
    static let composeSceneStoryboardId = "ReplyNavigation"

    /// Name of Storyboard that contains ComposeViewController.
    static let composeSceneStoryboard = "Main"

    /// Name of Storyboard that contains AddToContactsViewController.
    static let addToContactsStoryboard = "Reusable"

    /// Name of Storyboard that contains SuggestTableViewController.
    static let suggestionsStoryboard = "Reusable"
}
