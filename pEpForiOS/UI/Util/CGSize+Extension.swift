//
//  CGSize+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

extension CGSize {
    /**
     Default size for avatar images. Should also match storyboard sizes.
     */
    public static let defaultAvatarSize = CGSize(width: 48, height: 48)

    /**
     Default size for pEp rating image in avatar images.
     Related with `defaultAvatarSize`, and should be smaller.
     Should also match storyboard sizes.
     */
    public static let defaultAvatarPEPStatusSize = CGSize(width: 20, height: 20)
}
