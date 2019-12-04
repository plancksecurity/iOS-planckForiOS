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

    var SelectedIndexPath: IndexPath?

    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        configureAppearance()
        configureView()
    }

    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
    }

    private func configureView() {
        self.navigationController?.navigationBar.isHidden = !viewModel.isThereAnAccount()
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title:NSLocalizedString("Cancel", comment: "Login NavigationBar canel button title"),
            style:.plain, target:self,
            action:#selector(self.backButton))
    }

    @objc func backButton() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        SelectedIndexPath = indexPath
        performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "providerCell",
                                                for: indexPath) as? imageCollectionViewCell else {
            return UICollectionViewCell()
        }
        let cellProvider = viewModel[indexPath.row]
        switch cellProvider {
        case .GMail:
            cell.configure(withFileName: viewModel.fileNameOrText(provider: cellProvider))
        case .Other:
            cell.configure(withText: viewModel.fileNameOrText(provider: cellProvider))
        }
        return cell
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // this forces the collection view to have only 2 colums and all the cells with the same size
        let cellHeight = (view.frame.width*0.67)/2
        return CGSize(width: cellHeight, height: cellHeight)
    }
}

extension AccountTypeSelectorViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showLogin
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showLogin:
            if let vc = segue.destination as? LoginViewController,
                let selected = SelectedIndexPath {
                vc.appConfig = appConfig
                //loginView is not ready for this yet
//                switch viewModel[selected.row] {
//                case .GMail:
//                    vc.provider = true
//                case .Other:
//                    vc.provider = false
//                }
            }
        }
    }
}

/// Collection view cell class
public class imageCollectionViewCell: UICollectionViewCell {

    @IBOutlet var imageToFill: UIImageView!

    /// adds an image loaded from the file name
    /// - Parameter fileName: file name to load
    func configure(withFileName fileName: String) {
        let image = UIImage(named: fileName)
        imageToFill.image = image
    }

    /// adds an image created from a text
    /// - Parameter text: source text
    func configure(withText text: String) {
        let image = text.image(color: UIColor.pEpGreen)
        imageToFill.image = image
    }
}
