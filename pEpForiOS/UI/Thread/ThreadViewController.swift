//
//  ThreadViewController.swift
//  pEp
//
//  Created by Miguel Berrocal Gómez on 05/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class ThreadViewController: BaseViewController {
    var barItems: [UIBarButtonItem]?

    @IBOutlet weak var flagButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var model: ThreadedEmailViewModel!

    var numberOfMessages = 0 {
        didSet {
            self.navigationItem.title = String(numberOfMessages)  + " messages"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSplitViewBackButton()
        guard let model = model else {
            return
        }
        model.delegate = self
        numberOfMessages = model.rowCount()
        setUpFlaggedStatus()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func segueUnwindEmailDisplayDone(segue:UIStoryboardSegue) {
        //do nothing
    }

    func setUpFlaggedStatus(){
        let allFlagged =  model?.allMessagesFlagged() ?? false

        if allFlagged {
            flagButton.image = UIImage(named: "icon-flagged")
        } else {
            flagButton.image = UIImage(named: "icon-unflagged")
        }
    }
    
    private func configureSplitViewBackButton() {
        self.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    internal func isSplitViewControllerCollapsed() -> Bool! {
        guard let splitViewController = self.splitViewController else {
            Log.shared.errorAndCrash(component: #function, errorString: "We need a splitViewController here")
            return nil
        }
        return splitViewController.isCollapsed
    }

    // MARK: Actions
    
    @IBAction func flagButtonTapped(_ sender: Any) {
        guard let model = model else {
            return
        }
        model.setFlag(to: !model.allMessagesFlagged())
        setUpFlaggedStatus()
        
        tableView.reloadData()
    }

    @IBAction func moveToFolderTapped(_ sender: Any) {
        performSegue(withIdentifier: .segueShowMoveToFolder, sender: self)
    }

    @IBAction func destructiveButtonTapped(_ sender: Any) {
        model?.deleteAllMessages()
    }
    
    @IBAction func replyButtonTapped(_ sender: UIBarButtonItem) {

        let alert = ReplyAlertCreator()
            .withReplyOption { action in
                self.performSegue(withIdentifier: .segueReplyFrom , sender: self)
            }.withReplyAllOption { action in
                self.performSegue(withIdentifier: .segueReplyAllForm , sender: self)
            }.withFordwardOption { action in
                 self.performSegue(withIdentifier: .segueForward , sender: self)
            }.withCancelOption()
            .build()

        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }

        present(alert, animated: true, completion: nil)
    }

}
