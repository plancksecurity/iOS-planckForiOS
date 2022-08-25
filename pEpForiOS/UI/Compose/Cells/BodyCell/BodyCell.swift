//
//  BodyCell.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import UIKit

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

class BodyCell: TextViewContainingTableViewCell {
    static let reuseId = "BodyCell"

    private let defaultFontSize: CGFloat = 17.0

    var viewModel: BodyCellViewModel? {
        didSet {
            viewModel?.delegate = self
            viewModel?.maxTextattachmentWidth = textView.contentSize.width
            setupInitialText()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textView.font = UIFont.systemFont(ofSize: defaultFontSize)
        textView.accessibilityIdentifier = AccessibilityIdentifier.emailTextView
        textView.isAccessibilityElement = true
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
        textView.setLabelTextColor()
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
        textView.attributedText = attrText
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleTextChange(newText: textView.text,
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleCursorPositionChange(newPosition: cursorPosition)
    }

    public func textViewDidChange(_ textView: UITextView) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleTextChange(newText: textView.text,
                            newAttributedText: textView.attributedText)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.maxTextattachmentWidth = textView.bounds.width
        setupContextMenu()
        textView.setLabelTextColor()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleDidEndEditing(attributedText: textView.attributedText)
        tearDownContextMenu()
    }

    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("No VM")
            return true
        }
        return vm.handleShouldChangeText(in: range, of: textView.attributedText, with: text)
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
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        let media = UIMenuItem(title: vm.contextMenuItemTitleAddPhotoOrVideo,
                               action: #selector(userClickedSelectMedia))
        let attachment = UIMenuItem(title: vm.contextMenuItemTitleAddDocument,
                                    action: #selector(userClickedSelectDocument))
        UIMenuController.shared.menuItems = [media, attachment]
    }

    private func tearDownContextMenu() {
        UIMenuController.shared.menuItems = nil
    }

    @objc //required for usage in selector
    private func userClickedSelectMedia() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleUserClickedSelectMedia()
    }

    @objc //required for usage in selector
    private func userClickedSelectDocument() {
        guard let vm = viewModel else {
            Log.shared.errorAndCrash("VM not found")
            return
        }
        vm.handleUserClickedSelectDocument()
    }
}
