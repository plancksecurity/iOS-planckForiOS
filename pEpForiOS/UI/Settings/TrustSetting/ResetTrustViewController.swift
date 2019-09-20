//
//  ResetTrustViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 20/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class ResetTrustViewController: UIViewController {

    @IBOutlet var tableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

extension ResetTrustViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }


}
