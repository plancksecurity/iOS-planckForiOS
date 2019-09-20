//
//  ResetTrustViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class ResetTrustViewController: UIViewController {

    let viewModel = ResetTrustViewModel()

    @IBOutlet var tableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

    }

    func setupView() {
        ///Hide toolbar
        navigationController?.setToolbarHidden(true, animated: false)
    }

}

extension ResetTrustViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsPerSection(section: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForSection(section: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.indexElements()
    }


}
