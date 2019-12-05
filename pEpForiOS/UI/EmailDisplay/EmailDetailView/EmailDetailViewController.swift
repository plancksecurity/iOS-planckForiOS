//
//  EmailDetailViewController.swift
//  pEp
//
//  Created by Andreas Buff on 04.12.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

// Represents the a list of mails showing one mail with all details in full screen.
//BUFF: docs!
class EmailDetailViewController: BaseViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: EmailDetailViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    // MARK: - Target & Action

    @IBAction func flagButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func moveToFolderButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func destructiveButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }

    @IBAction func replyButtonPressed(_ sender: UIBarButtonItem) {
        fatalError()
    }
}

// MARK: - UICollectionViewDelegate

extension EmailDetailViewController: UICollectionViewDelegate {
    //

}

// MARK: - UICollectionViewDataSource

extension EmailDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
//        fatalError()
        return 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        fatalError()
        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension EmailDetailViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
