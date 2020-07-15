//
//  QuickViewDraftsViewController.swift
//  pEp
//
//  Created by Adam Kowalski on 15/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit

final class QuickViewDraftsViewController: UIViewController {

    static let storyboardId = "QuickViewDrafts"

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension QuickViewDraftsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: EmailListViewCell.storyboardId) else {
            Log.shared.errorAndCrash(message: "EmailListViewCell not found!")
            return UITableViewCell()
        }

        return cell
    }

}
