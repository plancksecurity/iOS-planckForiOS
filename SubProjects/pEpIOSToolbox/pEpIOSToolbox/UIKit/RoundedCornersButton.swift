//
//  RoundedCornersButton.swift
//  pEp
//
//  Created by Xavier Algarra on 22/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class RoundedCornersButton: UIButton {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        roundCorners(corners: .allCorners, radius: 5)
    }
}
