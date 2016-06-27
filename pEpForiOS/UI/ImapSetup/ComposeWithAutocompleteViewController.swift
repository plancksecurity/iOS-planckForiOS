//
//  ComposeWithAutocompleteViewController.swift
//  pEpForiOS
//
//  Created by ana on 1/6/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class ComposeViewControllerModel {
    var shortMessage: String? = nil
    var to: String? = nil
}

/**
 TODO:
  - Figure out how to react text changes from the user
  - When text changes, how to notify the table view so that it updates the height of just
    the right cell? Does reloadRowsAtIndexPaths work well?
  - How to correctly deal with ENTER so that it always enters newlines?
  - What about keyboard handling: User taps any key, do you have to make sure the right
    position of the text is still visible?
 */
class ComposeWithAutocompleteViewController: UITableViewController {
    let textFieldRowNumber = 4

    var appConfig: AppConfig?
    var model = ComposeViewControllerModel.init()

    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var ccTextField: UITextField!
    @IBOutlet weak var bccTextField: UITextField!
    @IBOutlet weak var shortMessageTextField: UITextField!
    @IBOutlet weak var longMessageTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIHelper.variableCellHeightsTableView(self.tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateView() {
        if let subject = model.shortMessage {
            shortMessageTextField.text = subject
        }
        if let to = model.to {
            toTextField.text = to
        }
    }

    // MARK: -- UITableViewDelegate

    override func tableView(tableView: UITableView,
                   heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let defaulHeight: CGFloat = 44
        if indexPath.row == textFieldRowNumber {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                let cellSize = cell.bounds.size
                let wantedSize = longMessageTextField.sizeThatFits(cellSize)
                return wantedSize.height
            }
            return defaulHeight
        } else {
            return defaulHeight
        }
    }
}

extension ComposeWithAutocompleteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return false
    }
}