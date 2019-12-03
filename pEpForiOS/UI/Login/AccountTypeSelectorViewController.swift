//
//  AccountTypeSelectorViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class AccountTypeSelectorViewController: BaseViewController {

    let viewModel = AccountTypeSelectorViewModel()

    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

    }

}

extension AccountTypeSelectorViewController: UICollectionViewDelegate {

}


extension AccountTypeSelectorViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "providerCell", for: indexPath) as? imageCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(provider: "blah")

        return cell
    }


}


public class imageCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageToFil: UIImageView!

    func configure(provider: String) {

        let image = UIImage(named: "pEpForIOS-Tutorial-horizontal-1")
        imageToFil.image = image
    }
}
