//
//  UIButton+extension.swift
//  pEpIOSToolbox
//
//  Created by Xavier Algarra on 12/08/2020.
//  Copyright © 2020 pEp Security SA. All rights reserved.
//

import UIKit

extension UIButton {
    public func roundCorners(corners: UIRectCorner, radius: CGFloat){
        clipsToBounds = true
        layer.cornerRadius = 0
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: corners,
                                    cornerRadii: CGSize(width: radius, height: radius))
        let maskLayer = CAShapeLayer()
        maskLayer.bounds = frame
        maskLayer.position = center
        maskLayer.path = maskPath.cgPath
        
        layer.mask = maskLayer
    }
}
