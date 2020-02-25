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
    var loginDelegate: LoginViewControllerDelegate?

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
        //as we need a title for the back button of the next view
        //but this title is not show
        //the view in the title are is replaced for a blank view.
        self.navigationItem.titleView = UIView()
        title = NSLocalizedString("Account Select", comment: "account type selector title")
        
        self.navigationController?.navigationBar.isHidden = !viewModel.isThereAnAccount()
        let imagebutton = UIButton(type: .custom)
        imagebutton.setImage(UIImage(named: "close-icon"), for: .normal)
        imagebutton.addTarget(self, action: #selector(backButton), for: .touchUpInside)
        imagebutton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let finalBarButton = UIBarButtonItem(customView: imagebutton)
        self.navigationItem.leftBarButtonItem = finalBarButton
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
                                                for: indexPath) as? AccountTypeSelectorCollectionViewCell else {
            return UICollectionViewCell()
        }
        let cellProvider = viewModel[indexPath.row]
        switch cellProvider {
        case .gmail:
            cell.configure(withFileName: viewModel.fileNameOrText(provider: cellProvider))
        case .other, .clientCertificate:
            cell.configure(withText: viewModel.fileNameOrText(provider: cellProvider))
        }
        return cell
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // this forces the collection view to have only 2 colums and all the cells with the same size
        let cellwidth = (view.frame.width*0.67)/2
        let cellHeight = 2*cellwidth/3
        return CGSize(width: cellwidth, height: cellHeight)
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
                vc.viewModel = LoginViewModel(accountType: viewModel[selected.row])
                vc.delegate = loginDelegate
            }
        }
    }
}
