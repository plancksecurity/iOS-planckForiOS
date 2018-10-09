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
//    let minHeigth: CGFloat = 58.0 //IOS-1369
    public let title = NSLocalizedString("Subject:",
                                         comment:
        "Title of subject field when composing a message")
    public var content: NSMutableAttributedString?
    public weak var resultDelegate: SubjectCellViewModelResultDelegate?

    init(resultDelegate: SubjectCellViewModelResultDelegate) {
        self.resultDelegate = resultDelegate
    }

    public func handleTextChanged(to text: NSAttributedString) {
        content = NSMutableAttributedString(attributedString: text)
        resultDelegate?.SubjectCellViewModelDidChangeSubject(self)
    }
}
