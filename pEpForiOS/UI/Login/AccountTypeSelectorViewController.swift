//
//  AccountTypeSelectorViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class AccountTypeSelectorViewController: BaseViewController {

    var viewModel: AccountTypeSelectorViewModel?
    var delegate: AccountTypeSelectorViewModelDelegate?
    var loginDelegate: LoginViewControllerDelegate?

    @IBOutlet var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        configureAppearance()
        configureView()
        configureViewModel()
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("no ViewModel")
            return
        }
        vm.delegate = self
    }

    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            self.navigationItem.leftBarButtonItem?.tintColor = .white
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("no ViewModel")
            return
        }
        self.navigationController?.navigationBar.isHidden = vm.isThereAnAccount()
        let imagebutton = UIButton(type: .custom)
        imagebutton.setImage(UIImage(named: "close-icon"), for: .normal)
        imagebutton.addTarget(self, action: #selector(backButton), for: .touchUpInside)
        imagebutton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let finalBarButton = UIBarButtonItem(customView: imagebutton)
        self.navigationItem.leftBarButtonItem = finalBarButton
    }
    
    private func configureViewModel() {
        if viewModel == nil {
            viewModel = AccountTypeSelectorViewModel()
        }
    }

    @objc func backButton() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel?.accountType(row: indexPath.row) {
        case .clientCertificate:
            viewModel?.handleDidChooseClientCertificate()
        default:
            viewModel?.handleDidSelect(rowAt: indexPath)
            performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
        }
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            return 0
            Log.shared.errorAndCrash("no ViewModel")
        }
        return vm.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "providerCell",
                                                            for: indexPath) as? AccountTypeSelectorCollectionViewCell,
                                                            let vm = viewModel else {
            return UICollectionViewCell()
        }
        let cellProvider = vm[indexPath.row]
        switch cellProvider {
        case .gmail:
            cell.configure(withFileName: vm.fileNameOrText(provider: cellProvider))
        case .other, .clientCertificate:
            cell.configure(withText: vm.fileNameOrText(provider: cellProvider))
        }
        return cell
    }
}

extension AccountTypeSelectorViewController: AccountTypeSelectorViewModelDelegate {
    func showClientCertificateSeletionView() {
        performSegue(withIdentifier: SegueIdentifier.clientCertManagementSegue,
                     sender: self)
    }

    func showMustImportClientCertificateAlert() {
        let title = NSLocalizedString("No Client Certificate",
                                      comment: "No client certificate exists alert title")
        let message = NSLocalizedString("No client certificate exists. You have to import your client certificate before entering login data.",
                                        comment: "No client certificate exists alert message")
        UIUtils.showAlertWithOnlyPositiveButton(title: title, message: message) { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.navigationController?.popViewController(animated: true)
        }
    }
}

extension AccountTypeSelectorViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var numberOfRows: CGFloat = 2.0
        if UIApplication.shared.statusBarOrientation.isLandscape {
            numberOfRows = 3.0
        }
        // this forces the collection view to have only 2 colums and all the cells with the same size
        let spaceBetweenCells: CGFloat = 30.0
        let cellwidth = (collectionView.frame.width - spaceBetweenCells)/numberOfRows
        let cellHeight = cellwidth/2
        return CGSize(width: cellwidth, height: cellHeight)
    }
}

extension AccountTypeSelectorViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showLogin
        case clientCertManagementSegue
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .showLogin:
            guard let vc = segue.destination as? LoginViewController,
                let vm = viewModel else {
                Log.shared.errorAndCrash("accountType is invalid")
                return
            }
            vc.appConfig = appConfig
            vc.viewModel = vm.loginViewModel()
            vc.delegate = loginDelegate
        case .clientCertManagementSegue:
            guard let dvc = segue.destination as? ClientCertificateManagementViewController,
                let vm = viewModel else {
                Log.shared.errorAndCrash("Invalid state")
                return
            }
            dvc.appConfig = appConfig
            dvc.viewModel = vm.clientCertificateManagementViewModel()
        }
    }
}
