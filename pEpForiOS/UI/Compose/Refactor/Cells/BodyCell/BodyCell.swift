//
//  BodyCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

class BodyCell: TextViewContainingTableViewCell {
    static let reuseId = "BodyCell"

    var viewModel: BodyCellViewModel? {
        didSet {
            viewModel?.delegate = self
        }
    }

    public func setup(with viewModel: BodyCellViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - BodyCellViewModelDelegate

extension BodyCell: BodyCellViewModelDelegate {
    //IOS-1369:
}

// MARK: - UITextViewDelegate

extension BodyCell {

    /*
     //IOS-1369: Next !!



     */
    public func textViewDidChange(_ textView: UITextView) {
        //IOS-1369: scroll?
        viewModel?.handleTextChange(newText: textView.text)
    }


    // WIP
    /*

     */
    //

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.becomeFirstResponder()
//        viewModel?.handleDidBeginEditing() //IOS-1369: obsolete?
        setupContextMenu()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        tearDownContextMenu()
        //        viewModel?.handleDidEndEditing() //IOS-1369: obsolete?
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let customItems: [UIMenuItem] = UIMenuController.shared.menuItems else {
            return super.canPerformAction(action, withSender: sender)
        }
        let actions = customItems.map { $0.action }
        if actions.contains(action) {
            return true
        }

        return super.canPerformAction(action, withSender: sender)
    }
}

// MARK: - Context Menu

extension BodyCell {
    private func setupContextMenu() {
        let media = UIMenuItem(title: viewModel?.contextMenuItemTitleAttachMedia ?? "",
                               action: #selector(userClickedSelectMedia))
        let attachment = UIMenuItem(title: viewModel?.contextMenuItemTitleAttachFile ?? "",
                                    action: #selector(userClickedSelectDocument))
        UIMenuController.shared.menuItems = [media, attachment]
    }

    private func tearDownContextMenu() {
        UIMenuController.shared.menuItems = nil
    }

    @objc //required for usage in selector
    private func userClickedSelectMedia() {
        viewModel?.handleUserClickedSelectMedia()
    }

    @objc //required for usage in selector
    private func userClickedSelectDocument() {
        viewModel?.handleUserClickedSelectDocument()
    }
}
