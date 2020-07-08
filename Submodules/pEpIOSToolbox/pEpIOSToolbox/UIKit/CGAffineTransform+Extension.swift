//
//  CGAffineTransform+Extension.swift
//  pEp
//
//  Created by Martin Brude on 29/06/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

extension CGAffineTransform {
    /// - Returns: An affine transformation matrix to rotate 90 degress.
    public static func rotate90Degress() -> CGAffineTransform {
        return CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
    }
}
