//
//  SubjectCellViewModel.swift
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

protocol SubjectCellViewModelResultDelegate: class {
    func subjectCellViewModelDidChangeSubject(_ vm: SubjectCellViewModel)
}

class SubjectCellViewModel: CellViewModel {
    public var content: String

    public weak var resultDelegate: SubjectCellViewModelResultDelegate?

    init(content: String = "", resultDelegate: SubjectCellViewModelResultDelegate?) {
        self.content = content
        self.resultDelegate = resultDelegate
    }

    public func handleTextChanged(to text: String) {
        content = text
        resultDelegate?.subjectCellViewModelDidChangeSubject(self)
    }

    public func shouldChangeText(to replacementText: String) -> Bool {
        if replacementText == "\n" {
            return false
        }
        return true
    }
}
