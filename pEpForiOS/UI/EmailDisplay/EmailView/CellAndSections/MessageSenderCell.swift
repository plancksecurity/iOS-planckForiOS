//
//  MessageSenderCell.swift
//  pEp
//
//  Created by Martín Brude on 11/2/21.
//  Copyright © 2021 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class MessageSenderCell: UITableViewCell {

    @IBOutlet public weak var fromLabel: UILabel!
    @IBOutlet public weak var toLabel: UILabel!
    @IBOutlet public weak var collectionView: UICollectionView!

    public func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 80, height: 30)
        collectionView.layout
        collectionView.reloadData()
    }
}
