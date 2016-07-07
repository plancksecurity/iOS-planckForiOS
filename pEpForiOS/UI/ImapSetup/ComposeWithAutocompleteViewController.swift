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

class ComposeWithAutocompleteViewController: UITableViewController {
    /**
     The index of the cell containing the body of the message for the user to write.
     Must be synchronized with the storyboard.
     */
    let textFieldRowNumber = 4

    var appConfig: AppConfig?
    var model = ComposeViewControllerModel.init()

    @IBOutlet weak var toTextField: UITextField!
    @IBOutlet weak var ccTextField: UITextField!
    @IBOutlet weak var bccTextField: UITextField!
    @IBOutlet weak var shortMessageTextField: UITextField!
    @IBOutlet weak var messageTableViewCell: UITableViewCell!
    @IBOutlet weak var longMessageTextField: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        longMessageTextField.resignFirstResponder()
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

    // MARK: -- UITextViewDelegate

    func textViewDidChange(textView: UITextView) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    // MARK: -- UITableViewDelegate

    override func tableView(tableView: UITableView,
                   heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == textFieldRowNumber {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                let inset = longMessageTextField.textContainerInset
                let lineFragmentPadding = longMessageTextField.textContainer.lineFragmentPadding
                var cellSize = cell.bounds.size
                cellSize.width -= (inset.left + inset.right + 2 * lineFragmentPadding)
                cellSize.height = CGFloat.max
                let wantedSize = longMessageTextField.sizeThatFits(cellSize)
                return wantedSize.height + inset.bottom + inset.top
            }
        }

        // Default if we don't have a better values, or for other cells
        return 44
    }
}