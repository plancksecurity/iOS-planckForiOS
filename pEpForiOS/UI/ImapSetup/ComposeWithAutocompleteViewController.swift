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

    // MARK: -- UITableViewDelegate

    override func tableView(tableView: UITableView,
                   heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let defaulHeight: CGFloat = 44
        if indexPath.row == textFieldRowNumber {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                var cellSize = cell.bounds.size
                //cellSize.height = CGFloat.max
                let wantedSize = longMessageTextField.sizeThatFits(cellSize)
                //longMessageTextField.bounds.size = cellSize
                let wantedSizeContent = longMessageTextField.contentSize
                return wantedSize.height + 64
            }
            return defaulHeight
        } else {
            return defaulHeight
        }
    }


    func textView(textView: UITextView, shouldChangeTextInRange  range: NSRange, replacementText text: String) -> Bool {
        textView.resignFirstResponder()
        let previousMessageInput = self.longMessageTextField.text
        //print(previousMessageInput)
        self.longMessageTextField.text = previousMessageInput! + text


        //let cell = tableView.cellForRowAtIndexPath(indexToReload)
        //var cellSize = cell!.bounds.size
        //let wantedSize = longMessageTextField.sizeThatFits(cellSize)
        //cell?.bounds.width = wantedSize.width
        //cell?.bounds.height = wantedSize.height

        let indexToReload = NSIndexPath(forItem: 4, inSection: 0)
        self.tableView.reloadRowsAtIndexPaths([indexToReload], withRowAnimation: UITableViewRowAnimation.Top)

       // messageCellNSLayoutConstraint.constant = 0
         //self.tableView.reloadData()
        /*self.tableView.reloadRowsAtIndexPaths([indexToReload], withRowAnimation: UITableViewRowAnimation.Top)*/
        //messageCellNSLayoutConstraint.constant = 500
        return true
    }
}

/*extension ComposeWithAutocompleteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return false
    }
}*/

/*extension UITextView {
    func calculateContentSize() -> CGSize {
        let contentSize = self.bounds.size
        let contentInserts = self.contentInset
        let contentainerInsets = self.textContainerInset

        var maxWidth = contentSize.width
        maxWidth -= 2.0 * self.textContainer.lineFragmentPadding
        maxWidth -= contentInset.left + contentInset.right + contentainerInsets.left
        + contentainerInsets.right

        var selectable = self.selectable
        self.selectable = true

        let textSize = self.attributedText.boundingRectWithSize(CGSizeMake(maxWidth, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)

        return contentSize
    }
}*/