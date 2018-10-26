//
//  SubjectCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol SubjectCellViewModelResultDelegate: class {
    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel)
}

protocol SubjectCellViewModelDelegate: class {
    func subjectCellViewModel(_ subjectCellViewModel: SubjectCellViewModel,
                                      requireFirstResponder: Bool)
}

class SubjectCellViewModel: CellViewModel {
    public let title = NSLocalizedString("Subject:",
                                         comment:
        "Title of subject field when composing a message")
    public var content: String?

    public weak var resultDelegate: SubjectCellViewModelResultDelegate?
    public weak var delegate: SubjectCellViewModelDelegate?

    init(resultDelegate: SubjectCellViewModelResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    public func handleTextChanged(to text: String) {
        content = text != "" ? text : " "
        resultDelegate?.subjectCellViewModelDidChangeSubject(self)
    }

    public func shouldChangeText(to replacementText: String) -> Bool {
        if replacementText == "\n" {
            delegate?.subjectCellViewModel(self, requireFirstResponder: false)
            return false
        }
        return true
    }
}
