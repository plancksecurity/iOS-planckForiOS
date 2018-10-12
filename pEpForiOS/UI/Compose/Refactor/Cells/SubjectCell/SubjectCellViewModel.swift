//
//  SubjectCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol SubjectCellViewModelResultDelegate: class {
    func SubjectCellViewModelDidChangeSubject(_ subjectCellViewModel: SubjectCellViewModel)
}

class SubjectCellViewModel: CellViewModel {
    public let title = NSLocalizedString("Subject:",
                                         comment:
        "Title of subject field when composing a message")
    public var content: String?

    public weak var resultDelegate: SubjectCellViewModelResultDelegate?

    init(resultDelegate: SubjectCellViewModelResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    public func handleTextChanged(to text: String) {
        content = text
        resultDelegate?.SubjectCellViewModelDidChangeSubject(self)
    }
}
