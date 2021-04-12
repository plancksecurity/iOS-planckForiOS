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
    @IBOutlet public weak var collectionView: MyCollectionView!

    public func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate) {
        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        setLayout()
    }

    func setLayout() {
        let flowLayout = MyCollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = CGSize(width: collectionView.frame.width / 2 - 10,
                                     height: collectionView.frame.width / 2 - 10)
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
    }
}


class MyCollectionViewFlowLayout: UICollectionViewFlowLayout {

}
