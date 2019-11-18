//
//  UIViewController+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit
import PEPObjCAdapterFramework

extension UIViewController {
    var isModalViewCurrentlyShown: Bool {
        return presentedViewController != nil
    }

    @discardableResult func showNavigationBarSecurityBadge(pEpRating: PEPRating?,
                                                           pEpProtection: Bool = true) -> UIView? {
        guard let img = pEpRating?.pEpColor().statusIconForMessage(enabled: pEpProtection) else {
            // No security badge image should be shown. Make sure to remove previously set img.
            navigationItem.titleView = nil
            return nil
        }
        // according to apple's design guidelines ('Hit Targets'):
        // https://developer.apple.com/design/tips/
        let minimumHitTestDimension: CGFloat = 44

        let imgView = UIImageView(image: img)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalTo: imgView.widthAnchor).isActive = true

        let badgeView = UIView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.heightAnchor.constraint(
            greaterThanOrEqualToConstant: minimumHitTestDimension).isActive = true

        badgeView.addSubview(imgView)

        let imagePadding: CGFloat = 10
        imgView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor).isActive = true
        imgView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor).isActive = true
        imgView.heightAnchor.constraint(lessThanOrEqualTo: badgeView.heightAnchor,
                                        constant: -imagePadding).isActive = true
        imgView.widthAnchor.constraint(lessThanOrEqualTo: badgeView.widthAnchor,
                                       constant: -imagePadding).isActive = true

        navigationItem.titleView = badgeView
        badgeView.isUserInteractionEnabled = true
        return badgeView
    }

    func showNavigationBarPEPLogo(pEpRating: PEPRating?) -> UIView? {
        if let rating = pEpRating, rating.isNoColor {
            if let img = UIImage(named: "icon-settings") {
                let minimumHittestDimension: CGFloat = 44
                let ImageWidht = self.navigationController!.navigationBar.bounds.height - 10
                let img2 = img.resized(newWidth: ImageWidht)
                let badgeView = UIImageView(image: img2)
                badgeView.contentMode = .center // DON'T stretch the image, leave it at original size

                // try to make the hit area of the icon a minimum of 44x44
                let desiredHittestDimension: CGFloat = min(
                    minimumHittestDimension,
                    navigationController?.navigationBar.frame.size.height ?? minimumHittestDimension)
                badgeView.bounds.size = CGSize(width: desiredHittestDimension, height: desiredHittestDimension)

                navigationItem.titleView = badgeView
                badgeView.isUserInteractionEnabled = true
                return badgeView
            }
            return nil
        }
        return nil
    }

    @discardableResult
    func presentKeySyncWizard(meFPR: String,
                              partnerFPR: String,
                              isNewGroup: Bool,
                              completion: @escaping (KeySyncWizardViewController.Action) -> Void )
        -> KeySyncWizardViewController? {
            guard let pageViewController = KeySyncWizardViewController.fromStoryboard(meFPR: meFPR,
                                                                                      partnerFPR: partnerFPR,
                                                                                      isNewGroup: isNewGroup,
                                                                                      completion: completion) else {
                                                                                        return nil
            }
            DispatchQueue.main.async { [weak self] in
                pageViewController.modalPresentationStyle = .overFullScreen
                self?.present(pageViewController, animated: true, completion: nil)
            }
            return pageViewController
    }

    @discardableResult
    /// Show simple UIActivityIndicatorView in midle of current view
    ///
    /// - Returns: UIActivityIndicatorView. Useful to hold for removing from super view
    func showActivityIndicator() -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)

        NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal,
                           toItem: view, attribute: .centerX, multiplier: 1,
                           constant: 0).isActive = true
        NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal,
                           toItem: view, attribute: .centerY, multiplier: 1,
                           constant: 0).isActive = true

        return activityIndicator
    }
}
