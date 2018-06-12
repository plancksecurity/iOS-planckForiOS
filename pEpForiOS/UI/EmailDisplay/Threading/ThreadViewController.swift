//
//  ThreadViewController.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 05/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class ThreadViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    var model: ThreadedEmailViewModel? = nil

    var messages = ["hola", "que", "tal"]
    var fullyDisplayedSections : [Bool] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        fullyDisplayedSections = Array(repeating: false, count: model?.rowCount() ?? 0)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
