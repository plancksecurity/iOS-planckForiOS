//
//  EditSignatureViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 12/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class EditSignatureViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    public var viewModel: EditSignatureViewModel?

    private var doOnce: (()->())?

    override func viewDidLoad() {
        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.tableView.reloadData()
            me.doOnce = nil
        }
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doOnce?()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let newSignature = getSignature() else {
            Log.shared.errorAndCrash("No signature")
            return
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.updateSignature(newSignature: newSignature)
    }

    func getSignature() -> String? {
        let presentedCellIndexPaht = IndexPath(row: 0, section: 0)
        guard let cell = tableView.cellForRow(at: presentedCellIndexPaht) as? SignatureTableViewCell else {
            return nil
        }
        return cell.editableSignature.text
    }
}

// MARK: - UITableViewDataSource

extension EditSignatureViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "SignatureCell") as? SignatureTableViewCell
        else {
            Log.shared.errorAndCrash("No cell")
            return UITableViewCell()
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        cell.editableSignature.text = vm.signature()
        return cell
    }
}
