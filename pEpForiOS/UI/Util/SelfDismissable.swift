//
//  SelfDismissable.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 19/07/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

protocol SelfDismissable {
    func configureDismissButton(with item:UIBarButtonItem.SystemItem)
}

@objc protocol Dismissable {
    func requestDismiss()
}

extension SelfDismissable where Self: UIViewController & Dismissable {

    func configureDismissButton(with item:UIBarButtonItem.SystemItem) {

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: item, target: self, action: #selector(requestDismiss))


        var items:[UIBarButtonItem] = [barButtonItem]

        if let leftItems = navigationItem.leftBarButtonItems {
            items.append(contentsOf: leftItems)
        }

        navigationItem.leftBarButtonItems = items

    }
}
