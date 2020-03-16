//
//  ClientCertificateManagementViewController.swift
//  pEp
//
//  Created by Andreas Buff on 24.02.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import SwipeCellKit

private struct Localized {
    static let importDate = NSLocalizedString("Import date",
                                              comment: "Select certificate - import certificate date")
}

/// View that lists all imported client certificates and let's the user choose one.
final class ClientCertificateManagementViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!

    public var viewModel: ClientCertificateManagementViewModel?
    
    //swipe acctions types
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    
    private var swipeDelete: SwipeAction? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        setupTableView()
        configureAppearance()
    }
}

// MARK: - Private

extension ClientCertificateManagementViewController {
    private func configureAppearance() {
        if #available(iOS 13, *) {
            Appearance.customiseForLogin(viewController: self)
        } else {
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.backgroundColor = UIColor.clear
        }
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.isHidden = false
    }

    private func setupTableView() {
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
    }
}

// MARK: - UITableViewDelegate

extension ClientCertificateManagementViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.handleDidSelect(rowAt: indexPath)
        performSegue(withIdentifier: SegueIdentifier.showLogin, sender: self)
    }
}

// MARK: - UITableViewDataSource

extension ClientCertificateManagementViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.rows.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ClientCertificateManagementTableViewCell.reusableId) as? ClientCertificateManagementTableViewCell else {
            Log.shared.errorAndCrash("No reusable cell")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            // We prefer empty cell than app crash
            return UITableViewCell()
        }
        let row = vm.rows[indexPath.row]
        let date = Localized.importDate + ": " + row.date
        cell.setData(title: row.name, date: date)
        return cell
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Hide seperator lines for empty view.
        return UIView()
    }
}

// MARK: - SegueHandlerType

extension ClientCertificateManagementViewController: SegueHandlerType {
    public enum SegueIdentifier: String {
        case showLogin
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        switch segueIdentifier(for: segue) {
        case .showLogin:
            guard let dvc = segue.destination as? LoginViewController else {
                    Log.shared.errorAndCrash("No DVC")
                    return
            }
            dvc.appConfig = appConfig
            let dvm = vm.loginViewModel()
            dvc.viewModel = dvm
        }
    }
}

extension ClientCertificateManagementViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        // Create swipe actions, taking the currently displayed folder into account
        var swipeActions = [SwipeAction]()
        let swipeActionDescriptor = SwipeActionDescriptor.trash
        let deleteAction =
            SwipeAction(style: .destructive,
                        title: swipeActionDescriptor.title(forDisplayMode: .titleAndImage)) {
                            [weak self] action, indexPath in
                            guard let me = self else {
                                Log.shared.errorAndCrash("Lost MySelf")
                                return
                            }
                            me.swipeDelete = action
                            //me.deleteAction(forCellAt: indexPath)
        }
        configure(action: deleteAction, with: swipeActionDescriptor)
        swipeActions.append(deleteAction)
        return swipeActions
    }
    
    func configure(action: SwipeAction, with descriptor: SwipeActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}
