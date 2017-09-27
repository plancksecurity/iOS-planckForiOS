//
//  GradientView.swift
//  pEp
//
//  Created by Dirk Zimmermann on 27.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class GradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(colors: [UIColor]) {
        super.init(frame: CGRect.zero)
        if let gradient = layer as? CAGradientLayer {
            gradient.frame = self.bounds
            gradient.colors = colors.map { $0.cgColor }
        }
    }
}
