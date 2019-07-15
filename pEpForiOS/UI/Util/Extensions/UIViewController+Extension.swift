//
//  UIViewController+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/02/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit
import PEPObjCAdapterFramework

extension UIViewController {
    var isModalViewCurrentlyShown: Bool {
        return presentedViewController != nil
    }

    @discardableResult func showPepRating(pEpRating: PEPRating?, pEpProtection: Bool = true) -> UIView? {
        if let img = pEpRating?.pEpColor().statusIcon(enabled: pEpProtection) {
            // according to apple's design guidelines ('Hit Targets'):
            // https://developer.apple.com/design/tips/
            let minimumHittestDimension: CGFloat = 44

            let minimumImageWidth = max(minimumHittestDimension / 2, img.size.width)
            let img2 = img.resized(newWidth: minimumImageWidth)
            let v = UIImageView(image: img2)
            v.contentMode = .center // DON'T stretch the image, leave it at original size

            // try to make the hit area of the icon a minimum of 44x44
            let desiredHittestDimension: CGFloat = min(
                minimumHittestDimension,
                navigationController?.navigationBar.frame.size.height ?? minimumHittestDimension)
            v.bounds.size = CGSize(width: desiredHittestDimension, height: desiredHittestDimension)

            navigationItem.titleView = v
            v.isUserInteractionEnabled = true
            return v
        } else {
            navigationItem.titleView = nil
            return nil
        }
    }

    func presentKeySyncHandShakeAlert(meFPR: String, partnerFPR: String,
                        completion: @escaping (KeySyncHandshakeViewController.Action) -> Void ) {

        let storyboard = UIStoryboard(name: "Reusable", bundle: .main)
        guard let handShakeViewController = storyboard.instantiateViewController(
            withIdentifier: KeySyncHandshakeViewController.storyboardId) as? KeySyncHandshakeViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController KeySyncHandshakeViewController")
                return
        }
        handShakeViewController.completion = { action in
            completion(action)
        }
        handShakeViewController.finderPrints(meFPR: meFPR, partnerFPR: partnerFPR)

        handShakeViewController.modalPresentationStyle = .overCurrentContext
        present(handShakeViewController, animated: true, completion: nil)
    }
}
