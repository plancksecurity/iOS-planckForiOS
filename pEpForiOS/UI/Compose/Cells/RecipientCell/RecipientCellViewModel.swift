//
//  RecipientCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol RecipientCellViewModelResultDelegate: class {
    func recipientCellViewModel(_ vm: RecipientCellViewModel,
                                didChangeRecipients newRecipients: [Identity])

    func recipientCellViewModel(_ vm: RecipientCellViewModel, didBeginEditing text: String)

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel)

    func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String)

    func addContactTapped()
}

class RecipientCellViewModel: CellViewModel {
    public let title: String
    private(set) var focused: Bool
    public var content = NSMutableAttributedString(string: "")
    public let type: FieldType
    private var initialRecipients = [Identity]()
    private var textViewModel: RecipientTextViewModel?
    public var isDirty: Bool {
        return textViewModel?.isDirty ?? false
    }

    weak public var resultDelegate: RecipientCellViewModelResultDelegate?
    weak var recipientCellDelegate: RecipientCellDelegate?

    init(resultDelegate: RecipientCellViewModelResultDelegate?,
         type: FieldType,
         recipients: [Identity] = []) {
        self.resultDelegate = resultDelegate
        self.type = type
        self.initialRecipients = recipients
        self.title = type.localizedTitle()
        self.focused = false
    }

    public func add(recipient: Identity) {
        textViewModel?.add(recipient: recipient)
    }

    func addContactAction() {
        resultDelegate?.addContactTapped()
    }

    func recipientTextViewModel() -> RecipientTextViewModel {
        if let existingVm = textViewModel {
            return existingVm
        }
        let createe = RecipientTextViewModel(resultDelegate: self, recipients: initialRecipients)
        textViewModel = createe
        return createe
    }
}

// MARK: - RecipientTextViewModelResultDelegate

extension RecipientCellViewModel: RecipientTextViewModelResultDelegate {

    func recipientTextViewModel(_ vm: RecipientTextViewModel, didChangeRecipients newRecipients: [Identity]) {
        resultDelegate?.recipientCellViewModel(self, didChangeRecipients: newRecipients)
    }

    func recipientTextViewModel(_ vm: RecipientTextViewModel, didBeginEditing text: String) {
        focused = true
        recipientCellDelegate?.focusChanged()
        resultDelegate?.recipientCellViewModel(self, didBeginEditing: text)
    }

    func recipientTextViewModelDidEndEditing(_ vm: RecipientTextViewModel) {
        focused = false
        recipientCellDelegate?.focusChanged()
        resultDelegate?.recipientCellViewModelDidEndEditing(self)
    }

    func recipientTextViewModel(_ vm: RecipientTextViewModel, textChanged newText: String) {
        resultDelegate?.recipientCellViewModel(self, textChanged: newText)
    }
}
