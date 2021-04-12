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
    @IBOutlet public weak var collectionView: CustomCollectionView!

    public func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        setLayout()
    }

    func setLayout() {
        let flowLayout = LeftAlignedCollectionViewFlowLayout()
        flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        flowLayout.scrollDirection = .horizontal
        flowLayout.estimatedItemSize = CGSize(width: frame.size.width, height: 30)
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
    }
}
