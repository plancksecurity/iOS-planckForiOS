//
//  DebugTableView.swift
//  pEp
//
//  Created by Dirk Zimmermann on 01.03.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

/**
 Meant for debugging layout problems involving table views.
 */
class DebugTableView: UITableView {
    override var contentOffset: CGPoint {
        didSet {
            print("contentOffset: \(contentOffset)")
        }
    }
}
