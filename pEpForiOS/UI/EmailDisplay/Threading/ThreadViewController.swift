//
//  ThreadViewController.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 05/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class ThreadViewController: BaseViewController {
    weak var delegate: EmailDisplayDelegate?

    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var model: ThreadedEmailViewModel? = nil

    var messages = ["hola", "que", "tal"]
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitViewBackButton()
        guard let model = model else {
            return
        }
        self.navigationItem.title = String(model.rowCount())  + " messages"
        setUpFlaggedStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setUpFlaggedStatus(){
        let allFlagged =  model?.allMessagesFlagged() ?? false

        if allFlagged {
            flagButton.image = UIImage(named: "icon-flagged")
        } else {
            flagButton.image = UIImage(named: "icon-unflagged")
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func configureSplitViewBackButton() {
        self.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    // MARK: Actions
    
    @IBAction func flagButtonTapped(_ sender: Any) {
        guard let model = model else {
            return
        }
        model.setFlag(to: !model.allMessagesFlagged())
        setUpFlaggedStatus()
        tableView.reloadData()
        delegate?.emailDisplayDidFlag(message: model.message(at: 0)!)
    }

    @IBAction func moveToFolderTapped(_ sender: Any) {
    }

    @IBAction func destructiveButtonTapped(_ sender: Any) {
        model?.deleteAllMessages()
    }
    
    @IBAction func replyButtonTapped(_ sender: Any) {
    }
}
