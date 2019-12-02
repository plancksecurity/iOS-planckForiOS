//
//  AccountTypeSelectorViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountTypeSelectorViewController: UIViewController {

    let viewModel = AccountTypeSelectorViewModel()

    @IBOutlet var Collection: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

}

extension AccountTypeSelectorViewController: UICollectionViewDelegate {

}


extension AccountTypeSelectorViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = UICollectionView.identifi
        return viewModel[indexPath.row]
    }


}
