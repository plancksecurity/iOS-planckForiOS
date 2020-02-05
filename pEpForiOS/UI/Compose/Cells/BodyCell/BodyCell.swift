//
//  BodyCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

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
            Log.shared.errorAndCrash("No VM")
            return
        }
        let (text, attrText) = vm.inititalText()
        if let attr = attrText {
            textView.attributedText = attr
        } else {
            textView.text = text
        }
        vm.handleTextChange(newText: textView.text, newAttributedText: textView.attributedText)
    }

    // MARK: - TextViewContainingTableViewCell

    // Set cursor and show keyboard
    override func setFocus() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return
        }
        if let rangeStart = textView.position(from: textView.beginningOfDocument,
                                              offset: vm.cursorPosition),
            let rangeEnd = textView.position(from: rangeStart, offset: 0) {
            textView.selectedTextRange = textView.textRange(from: rangeStart,
                                                            to: rangeEnd)
        }
        textView.becomeFirstResponder()
    }
}

// MARK: - BodyCellViewModelDelegate

extension BodyCell: BodyCellViewModelDelegate {

    func insert(text: NSAttributedString) {
        let selectedRange = textView.selectedRange
        let attrText = NSMutableAttributedString(attributedString: textView.attributedText)
        attrText.replaceCharacters(in: selectedRange, with: text)
        let font = UIFont.pepFont(style: .body, type: .regular)
        attrText.addAttribute(NSAttributedString.Key.font,
                              value: font,
                              range: NSRange(location: 0, length: attrText.length))
        textView.attributedText = attrText
        viewModel?.handleTextChange(newText: textView.text,
                                    newAttributedText: textView.attributedText)
    }
}

// MARK: - UITextViewDelegate

extension BodyCell {

    func textViewDidChangeSelection(_ textView: UITextView) {
        guard let textRange = textView.selectedTextRange else {
            // For some reason that happens sometimes when initializing the view.
            return
        }
        let cursorPosition = textView.offset(from: textView.beginningOfDocument,
                                             to: textRange.start)
        viewModel?.handleCursorPositionChange(newPosition: cursorPosition)
    }

    public func textViewDidChange(_ textView: UITextView) {
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
            Log.shared.errorAndCrash("No VM")
            return true
        }
       return vm.shouldReplaceText(in: range, of: textView.attributedText, with: text)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        tearDownContextMenu()
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
