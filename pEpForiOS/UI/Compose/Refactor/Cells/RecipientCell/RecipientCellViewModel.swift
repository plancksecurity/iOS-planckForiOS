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

    func recipientCellViewModelDidEndEditing(_ vm: RecipientCellViewModel)

    func recipientCellViewModel(_ vm: RecipientCellViewModel, textChanged newText: String)
}

//protocol RecipientCellViewModelDelegate {
//    //IOS-1369: TODO
//}

class RecipientCellViewModel: CellViewModel {
    public let title: String
    public var content = NSMutableAttributedString(string: "")
    public let type: FieldType
    private var initialRecipients = [Identity]()
    private var textViewModel: RecipientTextViewModel?

    weak public var resultDelegate: RecipientCellViewModelResultDelegate?

    init(resultDelegate: RecipientCellViewModelResultDelegate,
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

    func recipientTextViewModel() -> RecipientTextViewModel {
        let createe = RecipientTextViewModel(resultDelegate: self)
        textViewModel = createe
        return createe
    }
}

// MARK: - RecipientTextViewModelResultDelegate

extension RecipientCellViewModel: RecipientTextViewModelResultDelegate {
    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel, didChangeRecipients newRecipients: [Identity]) {
        resultDelegate?.recipientCellViewModel(self, didChangeRecipients: newRecipients)
    }

    func recipientTextViewModelDidEndEditing(recipientTextViewModel: RecipientTextViewModel) {
        resultDelegate?.recipientCellViewModelDidEndEditing(self)
    }

    func recipientTextViewModel(recipientTextViewModel: RecipientTextViewModel, textChanged newText: String) {
        resultDelegate?.recipientCellViewModel(self, textChanged: newText)
    }
}
