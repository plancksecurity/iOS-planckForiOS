//
//  RecipientCell.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class RecipientCell: UITableViewCell {
    let distanceRecipientTypeLabelSearchBox: CGFloat = 8
    let topBottomMinimumDistance: CGFloat = 4

    @IBOutlet weak var recipientTypeLabel: UILabel!

    var searchController: UISearchController? = nil {
        didSet {
            self.searchBar = searchController?.searchBar
        }
    }

    var searchBar: UISearchBar? = nil {
        didSet {
            if let old = oldValue {
                old.removeFromSuperview()
            }
            if let sb = searchBar {
                contentView.addSubview(sb)
                setupConstraintsWithSearchBar(sb)
            }
        }
    }

    var recipientType: RecipientType = .To {
        didSet {
            switch recipientType {
            case .To:
                recipientTypeLabel.text = NSLocalizedString("To:", comment: "ComposeView")
            case .CC:
                recipientTypeLabel.text = NSLocalizedString("CC:", comment: "ComposeView")
            case .BCC:
                recipientTypeLabel.text = NSLocalizedString("BCC:", comment: "ComposeView")
            }
        }
    }

    var message: Message!

    func setupConstraintsWithSearchBar(searchBar: UISearchBar) {
        searchBar.autoPinEdgeToSuperviewEdge(.Right)
        searchBar.autoPinEdge(.Left, toEdge: .Right, ofView: recipientTypeLabel, withOffset: distanceRecipientTypeLabelSearchBox)

        // minimum distance to top/bottom

        searchBar.autoPinEdge(.Top, toEdge: .Top, ofView: contentView,
                              withOffset: topBottomMinimumDistance,
                              relation: .GreaterThanOrEqual)
        searchBar.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView,
                              withOffset: -topBottomMinimumDistance,
                              relation: .LessThanOrEqual)

        recipientTypeLabel.autoPinEdge(.Top, toEdge: .Top, ofView: contentView,
                                       withOffset: topBottomMinimumDistance,
                                       relation: .GreaterThanOrEqual)
        recipientTypeLabel.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView,
                                       withOffset: -topBottomMinimumDistance,
                                       relation: .LessThanOrEqual)
    }
}