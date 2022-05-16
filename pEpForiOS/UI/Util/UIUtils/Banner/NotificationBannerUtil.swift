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


protocol NotificationBannerUtilProtocol {
    /// Show the error banner with the given message
    /// - Parameter errorMessage: The message to show
    static func show(errorMessage: String)

    /// Hide the banner
    ///
    /// - Parameter shouldSavePreference: Indicates if the global state should be reset.
    static func hide(shouldSavePreference: Bool)
}

class NotificationBannerUtil {

    private static let animateDuration = 0.5

    private static let minimunAmountOfSecondsSinceLastShown: TimeInterval = 30

    private static var heightConstraint: NSLayoutConstraint?

    public static func show(errorMessage: String) {
        DispatchQueue.main.async {
            let currentlyShownViewController = UIApplication.currentlyVisibleViewController()
            guard currentlyShownViewController is EmailListViewController || currentlyShownViewController is ComposeViewController else {
                //The banner MUST NOT be shown in other VCs than Email List and Compose.
                return
            }

            AppSettings.shared.bannerErrorMessage = errorMessage

            guard let navigationBar = currentlyShownViewController.navigationController?.navigationBar else {
                // Navigation bar not found, nothing to do.
                return
            }

            guard let errorBannerView = ErrorBannerView.loadViewFromNib(title: errorMessage) else {
                Log.shared.errorAndCrash(error: "Nib not found")
                return
            }

            if currentlyShownViewController.view.subviews.filter({ $0 is ErrorBannerView }).count > 0 {
                //A Banner view is already presented
                return
            }

            let sizeToFit = CGSize(width: navigationBar.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
            let sizeOfTitle = errorBannerView.titleLabel.sizeThatFits(sizeToFit)

            let margins: CGFloat = 16.0
            let bannerHeight = sizeOfTitle.height + margins
            errorBannerView.isHidden = true
            navigationBar.addSubview(errorBannerView)
            navigationBar.bringSubviewToFront(errorBannerView)
            errorBannerView.translatesAutoresizingMaskIntoConstraints = false

            print(bannerHeight)
            //Banner constraints
            let bannerWidthConstraint = NSLayoutConstraint(item: errorBannerView,
                                                           attribute: .width,
                                                           relatedBy: .equal,
                                                           toItem: navigationBar,
                                                           attribute: .width,
                                                           multiplier: 1,
                                                           constant: 0)

            let bannerCenterXConstraint = NSLayoutConstraint(item: errorBannerView,
                                                             attribute: .leading,
                                                             relatedBy: .equal,
                                                             toItem: navigationBar,
                                                             attribute: .leading,
                                                             multiplier: 1,
                                                             constant: 0)

            let bannerTopConstraint = NSLayoutConstraint(item: errorBannerView,
                                                         attribute: .top,
                                                         relatedBy: .equal,
                                                         toItem: navigationBar,
                                                         attribute: .bottom,
                                                         multiplier: 1,
                                                         constant: 0)

            var bannerHeightConstraint = NSLayoutConstraint(item: errorBannerView,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: 0)
            bannerHeightConstraint = bannerHeightConstraint.usingPriority(.required)
            self.heightConstraint = bannerHeightConstraint

            NSLayoutConstraint.activate([bannerWidthConstraint, bannerCenterXConstraint, bannerTopConstraint, bannerHeightConstraint])

            // Animate presentation
            errorBannerView.titleLabel.isHidden = true

            errorBannerView.isHidden = false
            navigationBar.layoutIfNeeded()

            // First, increase the distance between the tableView and the top of the view that is being displayed.
            UIView.animate(withDuration: animateDuration) {
                if let vc = currentlyShownViewController as? EmailListViewController {
                    vc.tableView.transform = CGAffineTransform(translationX: 0, y: bannerHeight)
                } else if let vc = currentlyShownViewController as? ComposeViewController {
                    vc.tableView.transform = CGAffineTransform(translationX: 0, y: 64 + bannerHeight)
                }
                bannerHeightConstraint.constant = bannerHeight
                navigationBar.layoutIfNeeded()
            } completion: { finished in
                // Then, show the UI components.
                errorBannerView.titleLabel.isHidden = false
            }
        }
    }

    /// Hide a Banner error view if exists
    public static func hide(shouldSavePreference: Bool) {
        if shouldSavePreference {
            AppSettings.shared.bannerErrorMessage = nil
        }
        DispatchQueue.main.async {
            let currentlyShownViewController = UIApplication.currentlyVisibleViewController()
            if let vc = currentlyShownViewController as? EmailListViewController {
                vc.tableView.transform = .identity
            } else if let vc = currentlyShownViewController as? ComposeViewController {
                vc.tableView.transform = .identity
            }

            guard let navigationBar = currentlyShownViewController.navigationController?.navigationBar else {
                // Navigation bar not found, nothing to do.
                return
            }

            guard let errorBannerView = navigationBar.subviews.filter ({ $0 is ErrorBannerView }).first as? ErrorBannerView else {
                //Nothing to remove. Banner does not exist.
                return
            }

            // First, increase the banner height.
            UIView.animate(withDuration: 0) {
                errorBannerView.titleLabel.isHidden = true
                heightConstraint?.constant = 0
                navigationBar.layoutIfNeeded()
            } completion: { finished in
                // Then, show the UI components.
                heightConstraint = nil
                errorBannerView.removeFromSuperview()
            }
        }
    }
}

