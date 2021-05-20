//
//  PEPAlignedCollectionViewFlowLayout.swift
//  pEp
//
//  Created by Martín Brude on 20/5/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit

class PEPAlignedCollectionViewFlowLayout: AlignedCollectionViewFlowLayout {

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        verticalAlignment = .top
        horizontalAlignment = .leading
        minimumLineSpacing = 3
        minimumInteritemSpacing = 2
    }
}
