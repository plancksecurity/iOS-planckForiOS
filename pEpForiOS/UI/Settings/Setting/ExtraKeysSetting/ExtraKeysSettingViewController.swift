//
//  ExtraKeysSettingViewController.swift
//  pEp
//
//  Created by Andreas Buff on 13.08.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

class ExtraKeysSettingViewController: BaseViewController {
    static private let uiTableViewCellID = "ExtraKeysSettingFprCell"

    @IBOutlet weak var addExtraKeyButton: UIButton!
    @IBOutlet weak var addFprView: UIStackView!
    @IBOutlet weak var fpr: UITextView!
    @IBOutlet weak var tableView: UITableView!

    private var viewModel: ExtraKeysSettingViewModel?

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
        tableView.reloadData()
    }

    @IBAction func addExtraKeyButtonPressed(_ sender: UIButton) {
        fatalError("Unimplemented stub")
    }
}

// MARK: - Private

extension ExtraKeysSettingViewController {
    private func setup() {
        tableView.dataSource = self
        tableView.delegate = self

        addExtraKeyButton.tintColor = UIColor.pEpGreen
//        addFprView.isHidden = !(viewModel?.isEditable ?? false)

        viewModel = ExtraKeysSettingViewModel()
    }
}

// MARK: - UITableViewDataSource

extension ExtraKeysSettingViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numRows ?? 0
    }

    func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: ExtraKeysSettingViewController.uiTableViewCellID,
                                          for: indexPath)
        cell.textLabel?.text = viewModel?[indexPath.row]

        return cell
    }
}


// MARK: - UITableViewDelegate

extension ExtraKeysSettingViewController: UITableViewDelegate {

}
