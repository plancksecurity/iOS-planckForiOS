//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

struct Constants { }

// MARK: - Storyboards & XIBs

extension Constants {
    /// Storyboard ID to instantiate ComposeViewController
    /// Is not in ComposeViewController.swift as it is the ID of the NavigationController that
    /// holds the ViewController, which the ViewController has no knowledge of.
    static let composeSceneStoryboardId = "ReplyNavigation"

    /// Name of the Main Storyboard
    static let mainStoryboard = "Main"

    /// Name of the Certificates Storyboard
    static let certificatesStoryboard = "Certificates"

    /// Name of Storyboard that contains SuggestTableViewController.
    static let reusableStoryboard = "Reusable"

    /// Name of Storyboard that contains KeySyncWizardViewController.
    static let keySyncWizardStoryboard = "Reusable"

    /// Storyboard ID to instantiate the navigation controller that contains Unsecure recipients list view.
    static let unsecureRecipientsListNavigation = "unsecureRecipientsListNavigationController"

    /// Name of the Recipients Storyboard
    static let recipientsStoryboard = "Recipients"

    struct XibNames {
        static let loadingInterface = "LoadingInterface"
    }
}

// MARK: - BGAppRefreshTask

extension Constants {
    static let appRefreshTaskBackgroundtaskBackgroundfetchSchedulerid =
        "security.pep.pep4ios.backgroundtaskschedulerid.backgroundfetch"
}

