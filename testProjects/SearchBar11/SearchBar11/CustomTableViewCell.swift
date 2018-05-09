//
//  CustomTableViewCell.swift
//  SearchBar11
//
//  Created by Dirk Zimmermann on 08.05.18.
//  Copyright © 2018 pEp Security AG. All rights reserved.
//

import Foundation
import UIKit

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}
