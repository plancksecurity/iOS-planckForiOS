//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpIOSToolbox

struct Constants {
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
    
    /// Name of Storyboard that contains View Controllers of the Tutorial.
    static let tutorialStoryboard = "Tutorial"

    /// Name of Storyboard that contains KeySyncWizardViewController.
    static let keySyncWizardStoryboard = "Reusable"

    /// Name of Storyboard that contains Folder related views.
    static let folderViewsStoryboard = "FolderViews"

    struct XibNames {
        static let loadingInterface = "LoadingInterface"
    }
}

