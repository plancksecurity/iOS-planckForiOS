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

    @discardableResult func showPepRating(pEpRating: PEPRating?, pEpProtection: Bool = true, showGreyBadge: Bool = true) -> UIView? {
        if pEpRating?.uiColor() != UIColor.gray {
            if let img = pEpRating?.pEpColor().statusIconForMessage(enabled: pEpProtection) {
                // according to apple's design guidelines ('Hit Targets'):
                // https://developer.apple.com/design/tips/
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
            } else {
                navigationItem.titleView = nil
                return nil
            }
        }
        return nil
    }

    func presentKeySyncWizard(meFPR: String,
                              partnerFPR: String,
                              isNewGroup: Bool,
                              completion: @escaping (KeySyncWizard.Action) -> Void ) {
        guard let pageViewController = KeySyncWizard.fromStoryboard(meFPR: meFPR,
                                                                    partnerFPR: partnerFPR,
                                                                    isNewGroup: isNewGroup,
                                                                    completion: completion) else {
                                                                        return
        }
        DispatchQueue.main.async { [weak self] in
            if let presented = self?.presentedViewController {
                presented.dismiss(animated: true, completion: {
                    self?.present(pageViewController, animated: true, completion: nil)
                })
            } else {
                self?.present(pageViewController, animated: true, completion: nil)
            }
        }
    }
}
