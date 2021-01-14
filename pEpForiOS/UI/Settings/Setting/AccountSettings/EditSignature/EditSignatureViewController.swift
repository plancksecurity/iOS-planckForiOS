//
//  EditSignatureViewController.swift
//  pEp
//
//  Created by Xavier Algarra on 12/08/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

class EditSignatureViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    public var viewModel: EditSignatureViewModel?

    override var collapsedBehavior: CollapsedSplitViewBehavior {
        return .needed
    }

    override var separatedBehavior: SeparatedSplitViewBehavior {
        return .detail
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Signature", comment: "Edit Signature title")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        vm.updateSignature()
    }
}

// MARK: - UITableViewDataSource

extension EditSignatureViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return 0
        }
        return vm.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignatureTableViewCell") as? SignatureTableViewCell
        else {
            Log.shared.errorAndCrash("No cell")
            return UITableViewCell()
        }
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return UITableViewCell()
        }
        cell.textView.text = vm.signature()
        return cell
    }
}

// MARK: UITextViewDelegate

extension EditSignatureViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return false
        }
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        vm.signatureInProgress = updatedText
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        // Calculate if the textView will change its height.
        // If so, update the tableView.
        // Also disable animations to prevent "jankiness".

        let textViewHeight = textView.frame.size.height
        let textViewNewHeight = textView.sizeThatFits(textView.frame.size).height

        guard textViewHeight != textViewNewHeight else {
            return
        }
        UIView.setAnimationsEnabled(false) // Disable animations
        tableView.beginUpdates()
        tableView.endUpdates()

        let scrollTo = tableView.contentSize.height - tableView.frame.size.height
        let point = CGPoint(x: 0, y: scrollTo)
        tableView.setContentOffset(point, animated: false)

        UIView.setAnimationsEnabled(true)  // Re-enable animations.
    }
}
