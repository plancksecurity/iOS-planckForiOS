//
//  UIBarButtonItem+Extension.swift
//  pEp
//
//  Created by Xavier Algarra on 11/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    public static func getpEpButton(action: Selector, target: Any) {

        let pepButton = UIBarButtonItem(image: nil, style: .plain, target: target, action: action)

    }
}
