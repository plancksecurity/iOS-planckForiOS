//
//  RecipientCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

protocol RecipientCellViewModelResultDelegate: AnyObject {
    func recipientCellViewModel(_ vm: RecipientCellViewModel,
                                didChangeRecipients newRecipients: [Identity])

    func recipientCellViewModel(_ vm: RecipientCellViewModel, didBeginEditing text: String)

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel)

    func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String)

    func addContactTapped()
}

protocol RecipientCellViewModelDelegate: AnyObject {
    func focusChanged()
}

class RecipientCellViewModel: CellViewModel {
    public let title: String
    public var content = NSMutableAttributedString(string: "")
    public let type: FieldType
    private(set) var focused = false
    private var initialRecipients = [Identity]()
    private var textViewModel: RecipientTextViewModel?
    public var isDirty: Bool {
        return textViewModel?.isDirty ?? false
    }

    weak public var resultDelegate: RecipientCellViewModelResultDelegate?
    weak var recipientCellViewModelDelegate: RecipientCellViewModelDelegate?

    init(resultDelegate: RecipientCellViewModelResultDelegate?,
         type: FieldType,
         recipients: [Identity] = []) {
        self.resultDelegate = resultDelegate
        self.type = type
        self.initialRecipients = recipients
        self.title = type.localizedTitle()
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
        focused = true
        recipientCellViewModelDelegate?.focusChanged()
        resultDelegate?.recipientCellViewModel(self, didChangeRecipients: newRecipients)
    }

    func recipientTextViewModel(_ vm: RecipientTextViewModel, didBeginEditing text: String) {
        focused = true
        recipientCellViewModelDelegate?.focusChanged()
        resultDelegate?.recipientCellViewModel(self, didBeginEditing: text)
    }

    func recipientTextViewModelDidEndEditing(_ vm: RecipientTextViewModel) {
        focused = false
        recipientCellViewModelDelegate?.focusChanged()
        resultDelegate?.recipientCellViewModelDidEndEditing(self)
    }

    func recipientTextViewModel(_ vm: RecipientTextViewModel, textChanged newText: String) {
        resultDelegate?.recipientCellViewModel(self, textChanged: newText)
    }
}
