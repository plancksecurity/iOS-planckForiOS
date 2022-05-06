//
//  NotificationBannerUtil.swift
//  pEp
//
//  Created by Martín Brude on 3/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//


import UIKit
import Foundation
import pEpIOSToolbox

class NotificationBannerUtil {

    private static let animateDuration = 0.5
    private static let minimunAmountOfSecondsSinceLastShown: TimeInterval = 30
    private static let bannerHeight = CGFloat(44)

    public static func show(error: DisplayUserError) {
        let currentlyShownViewController = UIApplication.currentlyVisibleViewController()
        guard let navBar = currentlyShownViewController.navigationController?.navigationBar else {
            // Navigation bar not found, nothing to do.
            return
        }
        guard let superview = currentlyShownViewController.view  else {
            Log.shared.errorAndCrash(error: "Superview not found")
            return
        }

        guard let errorLogToBeCopied = error.extraInfo,
              let view = ErrorBannerView.loadViewFromNib(errorLogToBeCopied: errorLogToBeCopied,
                                                         title: error.title,
                                                         subtitle: error.errorDescription ?? "") else {
            Log.shared.errorAndCrash(error: "Nib not found")
            return
        }

        if let lastTimeShown = AppSettings.shared.lastBannerErrorPresentationDatetime {
            let elapsed = Date().timeIntervalSince(lastTimeShown)
            guard elapsed > minimunAmountOfSecondsSinceLastShown else {
                //Do not bother the users innecesarily.
                return
            }
        }

        view.isHidden = true
        superview.addSubview(view)
        superview.bringSubviewToFront(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        //Banner constraints
        let bannerWidthConstraint = NSLayoutConstraint(item: view,
                                                       attribute: .width,
                                                       relatedBy: .equal,
                                                       toItem: superview,
                                                       attribute: .width,
                                                       multiplier: 1,
                                                       constant: 0)

        let bannerCenterXConstraint = NSLayoutConstraint(item: view,
                                                         attribute: .leading,
                                                         relatedBy: .equal,
                                                         toItem: superview,
                                                         attribute: .leading,
                                                         multiplier: 1,
                                                         constant: 0)

        let bannerTopConstraint = NSLayoutConstraint(item: view,
                                                     attribute: .top,
                                                     relatedBy: .equal,
                                                     toItem: navBar,
                                                     attribute: .bottom,
                                                     multiplier: 1,
                                                     constant: 0)

        var bannerHeightConstraint = NSLayoutConstraint(item: view,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1,
                                              constant: 0)
        bannerHeightConstraint = bannerHeightConstraint.usingPriority(.required)

        NSLayoutConstraint.activate([bannerWidthConstraint, bannerCenterXConstraint, bannerTopConstraint, bannerHeightConstraint])

        // Animate presentation
        view.subtitleLabel.isHidden = true
        view.titleLabel.isHidden = true
        view.copyLogButton.isHidden = true
        view.closeButton.isHidden = true

        view.isHidden = false
        superview.layoutIfNeeded()

        // First, increase the banner height.
        UIView.animate(withDuration: animateDuration) {
            bannerHeightConstraint.constant = bannerHeight
            superview.layoutIfNeeded()
        } completion: { finished in
            // Then, show the UI components.
            view.subtitleLabel.isHidden = false
            view.titleLabel.isHidden = false
            view.copyLogButton.isHidden = false
            view.closeButton.isHidden = false
            AppSettings.shared.lastBannerErrorPresentationDatetime = Date()
        }
    }
}

