//
//  NotificationBannerUtil.swift
//  pEp
//
//  Created by Martín Brude on 3/5/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import UIKit
import Foundation
#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

protocol NotificationBannerUtilProtocol {

    /// Show the error banner with the given message
    ///
    /// - Parameter errorMessage: The message to show
    static func show(errorMessage: String, currentlyShownViewController: UIViewController?)

    /// Hide the banner
    static func hide(currentlyShownViewController: UIViewController?)
}

class NotificationBannerUtil: NotificationBannerUtilProtocol {

    // MARK: - Private

    private static let animateDuration = 0.5

    private static let minimunAmountOfSecondsSinceLastShown: TimeInterval = 30

    private static var heightConstraint: NSLayoutConstraint?

    // MARK: - Public

    public static func show(errorMessage: String, currentlyShownViewController: UIViewController? = nil) {
        /// The framework Apple introduce to monitor network status does not work properly on simulators.
#if !targetEnvironment(simulator)
        DispatchQueue.main.async {
            var vc: UIViewController
            if let viewController = currentlyShownViewController {
                vc = viewController
            } else {
                vc = UIApplication.currentlyVisibleViewController()
            }

            // In sharing extesion target, only will be shown on Compose view.
            // In pEp target, only will be shown on Compose view and Email List view.
#if EXT_SHARE
            guard vc is ComposeViewController else {
                //The banner MUST NOT be shown in other VCs than Compose.
                return
            }
#else
            guard vc is EmailListViewController || vc is ComposeViewController || SettingsTableViewController else {
                //The banner MUST NOT be shown in other VCs than Email List and Compose.
                return
            }
#endif

            guard let navigationBar = vc.navigationController?.navigationBar else {
                // Navigation bar not found, nothing to do.
                return
            }

            guard let errorBannerView = ErrorBannerView.loadViewFromNib(title: errorMessage) else {
                Log.shared.errorAndCrash(error: "Nib not found")
                return
            }

            if navigationBar.subviews.filter({ $0 is ErrorBannerView }).count > 0 {
                //A Banner view is already presented
                return
            }

            let sizeToFit = CGSize(width: navigationBar.frame.size.width, height: .greatestFiniteMagnitude)
            let sizeOfTitle = errorBannerView.titleLabel.sizeThatFits(sizeToFit)

            let verticalMargins: CGFloat = 16.0
            let bannerHeight = sizeOfTitle.height + verticalMargins
            errorBannerView.isHidden = true
            navigationBar.addSubview(errorBannerView)
            navigationBar.bringSubviewToFront(errorBannerView)
            errorBannerView.translatesAutoresizingMaskIntoConstraints = false

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

                if let vc = vc as? ComposeViewController {
                    vc.tableView.transform = CGAffineTransform(translationX: 0, y: 64 + bannerHeight)
                } else if let tv = vc.view.subviews.filter({$0 is UITableView} ).first {
                    tv.transform = CGAffineTransform(translationX: 0, y: bannerHeight)
                }

                bannerHeightConstraint.constant = bannerHeight
                navigationBar.layoutIfNeeded()
            } completion: { finished in
                // Then, show the UI components.
                errorBannerView.titleLabel.isHidden = false
            }
        }
#endif
    }

    /// Hide a Banner error view if exists
    public static func hide(currentlyShownViewController: UIViewController? = nil) {
        DispatchQueue.main.async {
            var vc: UIViewController
            if let viewController = currentlyShownViewController {
                vc = viewController
            } else {
                vc = UIApplication.currentlyVisibleViewController()
            }

            guard let navigationBar = vc.navigationController?.navigationBar else {
                // Navigation bar not found, nothing to do.
                return
            }

            guard let errorBannerView = navigationBar.subviews.filter ({ $0 is ErrorBannerView }).first as? ErrorBannerView else {
                //Nothing to remove. Banner does not exist.
                return
            }

            // First, increase the banner height.
            UIView.animate(withDuration: animateDuration) {
                if let tv = vc.view.subviews.filter({$0 is UITableView}).first {
                    tv.transform = .identity
                }
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
