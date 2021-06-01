//
//  Constants.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 28/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
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

    /// Name of Storyboard that contains View Controllers of the Tutorial for iPad.
    static let tutorialiPadStoryboard = "Tutorial_iPad"

    /// Name of Storyboard that contains View Controllers of the Tutorial for iPhone.
    static let tutorialiPhoneStoryboard = "Tutorial_iPhone"
    
    /// Name of Storyboard that contains Reusable views.
    static let reusableStoryboard = "Reusable"
    
    /// Name of Storyboard that contains View Controllers of the Tutorial.
    static let tutorialStoryboard = "Tutorial"

    struct XibNames {
        static let loadingInterface = "LoadingInterface"
    }
}

// MARK: - BGAppRefreshTask

extension Constants {
    static let appRefreshTaskBackgroundtaskBackgroundfetchSchedulerid =
        "security.pep.pep4ios.backgroundtaskschedulerid.backgroundfetch"
}

