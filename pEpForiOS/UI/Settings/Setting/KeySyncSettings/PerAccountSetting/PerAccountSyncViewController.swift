//
//  PerAccountSyncViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 07/01/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

class PerAccountSyncViewController: UIViewController {

    let viewModel = PerAccountSyncViewModel()

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension PerAccountSyncViewController: UITableViewDelegate {

}

extension PerAccountSyncViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell") else {
            Log.shared.errorAndCrash(message: "cell not found")
            return UITableViewCell()
        }
        
        return cell
    }

}
