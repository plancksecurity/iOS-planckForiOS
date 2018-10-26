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
            viewModel?.maxTextattachmentWidth = textView.contentSize.width
            setupInitialText()
        }
    }

    public func setup(with viewModel: BodyCellViewModel) {
        self.viewModel = viewModel
    }

    private func setupInitialText() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "No VM")
            return
        }
        let (text, attrText) = vm.inititalText()
        if let attr = attrText {
            textView.attributedText = attr
        } else {
            textView.text = text
        }
        viewModel?.handleTextChange(newText: textView.text,
                                    newAttributedText: textView.attributedText)
    }
}

// MARK: - BodyCellViewModelDelegate

extension BodyCell: BodyCellViewModelDelegate {

    func insert(text: NSAttributedString) {
        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: text)
        textView.attributedText = attrText
        viewModel?.handleTextChange(newText: textView.text,
                                    newAttributedText: textView.attributedText)
    }
}

// MARK: - UITextViewDelegate

extension BodyCell {

    public func textViewDidChange(_ textView: UITextView) {
        //IOS-1369: scroll?
        viewModel?.handleTextChange(newText: textView.text,
                                    newAttributedText: textView.attributedText)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        viewModel?.maxTextattachmentWidth = textView.bounds.width
        setupContextMenu()
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash(component: #function, errorString: "No VM")
            return true
        }
       return vm.shouldReplaceText(in: range, of: textView.attributedText, with: text)
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
