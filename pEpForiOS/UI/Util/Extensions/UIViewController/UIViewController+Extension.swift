//
//  UIViewController+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import MessageModelForAppExtensions
import pEpIOSToolboxForExtensions
#else
import MessageModel
import pEpIOSToolbox
#endif

extension UIViewController {

    var isModalViewCurrentlyShown: Bool {
        return presentedViewController != nil
    }
    var usesAccessibilityFont : Bool {
        return traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    }

    /// As this screen might be rendered in a split view, the title view is not centered to the device
    /// width but the view controller's width. That's why we need to adjust the title view position
    /// in that case.
    /// - Note: When running in the extension target, nothing is adjusted.
    func adjustTitleViewPositionIfNeeded() {
        #if !EXT_SHARE // Ignore completely when running in the extension
        //reset previous transformations if any
        navigationItem.titleView?.transform = .identity
        if UIDevice.isIpad && UIDevice.isLandscape {
            let oldCenterX = view.center.x
            let newCenterX = UIScreen.main.bounds.size.width / 2
            let deltaX = oldCenterX - newCenterX
            navigationItem.titleView?.transform =
                CGAffineTransform.identity.translatedBy(x: deltaX, y: 0)
        }
        #endif
    }
    
    /// Puts the privacy rating or pEp logo into the navigation item or removes it.
    ///
    /// When running on layouts _without_ a split view (that is, on smaller iPhones),
    /// and there is no rating or it's "no color", the pEp logo will be returned instead.
    /// - Parameter pEpRating: The privacy rating, or nil.
    /// - Parameter pEpProtection: False if the user decided to "force unprotected",
    ///   true otherwise.
    /// - Returns: The view that was put into the navigation item title, or nil,
    ///   if no view was put there. In that case, the navigation item title view has
    ///   been nil'ed.
    @discardableResult func showNavigationBarSecurityBadge(pEpRating: Rating?,
                                                           pEpProtection: Bool = true) -> UIView? {
        let titleView = navigationItemTitleView(pEpRating: pEpRating, pEpProtection: pEpProtection)
        titleView?.isUserInteractionEnabled = true
        navigationItem.titleView = titleView
        navigationItem.titleView?.accessibilityIdentifier = "View title"
        adjustTitleViewPositionIfNeeded()
        return titleView
    }

    private func navigationItemTitleView(pEpRating: Rating?, pEpProtection: Bool = true) -> UIView? {
        if let color = pEpRating?.pEpColor(),
            let image = color.statusIconForMessage(enabled: pEpProtection) {
            // according to apple's design guidelines ('Hit Targets'):
            // https://developer.apple.com/design/tips/
            let minimumHitTestDimension: CGFloat = 44

            let imageView = UIImageView(image: image)
            var accessibilityIdentifier: String
            switch color {
            case .noColor:
                accessibilityIdentifier = AccessibilityIdentifier.unknownTrust
            case .yellow:
                accessibilityIdentifier = AccessibilityIdentifier.secure
            case .green:
                accessibilityIdentifier = AccessibilityIdentifier.secureAndTrusted
            case .red:
                accessibilityIdentifier = AccessibilityIdentifier.mistrusted
            }
            imageView.accessibilityIdentifier = accessibilityIdentifier

            imageView.translatesAutoresizingMaskIntoConstraints = false
            let aspectRatio = imageView.aspectRatio()
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0/aspectRatio).isActive = true

            let badgeView = UIView()
            badgeView.translatesAutoresizingMaskIntoConstraints = false
            badgeView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: minimumHitTestDimension).usingPriority(.almostRequired).isActive = true
            badgeView.addSubview(imageView)

            let imagePadding: CGFloat = 10
            let imageViewHeight = minimumHitTestDimension - imagePadding
            imageView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor).isActive = true
            imageView.heightAnchor.constraint(lessThanOrEqualTo: badgeView.heightAnchor,
                                            constant: -imagePadding).isActive = true
            imageView.heightAnchor.constraint(greaterThanOrEqualToConstant: imageViewHeight).usingPriority(.almostRequired).isActive = true

            imageView.widthAnchor.constraint(lessThanOrEqualTo: badgeView.widthAnchor,
                                           constant: -imagePadding).isActive = true

            return badgeView
        }
        return nil
    }

    func hideNavigationBarIfSplitViewShown() {
        if !onlySplitViewMasterIsShown {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    func showNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    /// Dismiss the presentedViewController if exists and perform the action.
    /// - Parameter completion: The action to be performed.
    func dismissAndPerform(completion: (() -> Void)? = nil) {
        if let presentedViewController = presentedViewController {
            presentedViewController.dismiss(animated: true) {
                completion?()
            }
        } else {
            completion?()
        }
    }
}

// MARK: - SplitViewControllerBehaviorProtocol
extension UIViewController: SplitViewControllerBehaviorProtocol {
    /// Method to detect the actual status of the splitViewController
    ///
    /// - Returns: returns the value of the actual status of the split view controller using SplitViewDisplayMode
    func currentSplitViewMode() -> UISplitViewController.SplitViewDisplayMode {
        if let selfsplit = self as? UISplitViewController {
            return selfsplit.currentDisplayMode
        }
        guard let splitview = splitViewController else {
            return .onlyMaster
        }
        return splitview.currentDisplayMode
    }
    
    var onlySplitViewMasterIsShown: Bool {
        get {
            return currentSplitViewMode() == .onlyMaster
        }
    }
    
    var collapsedBehavior: CollapsedSplitViewBehavior {
        return .disposable
    }
    
    var separatedBehavior: SeparatedSplitViewBehavior {
        return .master
    }
    
    /// If applicable, shows the "empty selection" view controller in the details view.
    /// - Parameter message: The message to show in the view.
    func showEmptyDetailViewIfApplicable(message: String) {
        guard let spvc = splitViewController else {
            return
        }
        
        /// Inner function for doing the actual work.
        func showEmptyDetail() {
            let detailIndex = 1 // The index of the detail view controller
            
            if let emptyVC = spvc.viewControllers[safe: detailIndex] as? NothingSelectedViewController {
                emptyVC.message = message
                emptyVC.updateView()
            } else {
                let storyboard: UIStoryboard = UIStoryboard(
                    name: UIStoryboard.noSelectionStoryBoard,
                    bundle: nil)
                guard let detailVC = storyboard.instantiateViewController(
                    withIdentifier: UIStoryboard.nothingSelectedViewController) as? NothingSelectedViewController else {
                        return
                }
                detailVC.message = message
                spvc.showDetailViewController(detailVC, sender: self)
            }
        }
        
        switch spvc.currentDisplayMode {
        case .masterAndDetail:
            showEmptyDetail()
        case .onlyDetail:
            // nothing to do
            break
        case .onlyMaster:
            // nothing to do
            break
        }
    }
}
