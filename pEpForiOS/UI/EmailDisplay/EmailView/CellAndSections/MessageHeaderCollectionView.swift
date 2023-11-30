//
//  MessageHeaderCollectionView.swift
//  pEp
//
//  Created by Martín Brude on 26/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

@IBDesignable
class MessageHeaderCollectionView: UICollectionView {

    public var type: EmailViewModel.RecipientType = .from

    // Enums are not supported in IB, so we use a string instead.
    @IBInspectable var typeName: String? {
        willSet {
            guard let newType = EmailViewModel.RecipientType(rawValue: newValue?.lowercased() ?? "") else {
                Log.shared.errorAndCrash("Typo in interface builder 'type' field")
                return
            }
            type = newType
        }
    }
}
