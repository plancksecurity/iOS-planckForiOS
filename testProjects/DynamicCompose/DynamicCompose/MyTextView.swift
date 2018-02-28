//
//  MyTextView.swift
//  DynamicCompose
//
//  Created by Dirk Zimmermann on 28.02.18.
//  Copyright © 2018 pEp Security AG. All rights reserved.
//

import UIKit

class MyTextView: UITextView {
    override var frame: CGRect {
        get {
            return super.frame
        }

        set {
            print("frame.size: \(frame.size)")
        }
    }

    override var bounds: CGRect {
        get {
            return super.bounds
        }

        set {
            print("bounds.size: \(bounds.size)")
        }
    }

    override var intrinsicContentSize: CGSize {
        get {
            let currentSize = self.frame.size
            let fittingSize = sizeThatFits(CGSize(width: currentSize.width,
                                                  height: CGFloat.greatestFiniteMagnitude))
            print("fittingSize: \(fittingSize)")
            return fittingSize
        }
    }
}
