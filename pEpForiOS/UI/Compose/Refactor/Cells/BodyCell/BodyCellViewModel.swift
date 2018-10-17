//
//  BodyCellViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 05.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel


protocol BodyCellViewModelResultDelegate: class {
    func bodyCellViewModel(_ vm: BodyCellViewModel, textChanged newText: String)
}

protocol BodyCellViewModelDelegate: class {
    //IOS-1369:
}

class BodyCellViewModel: CellViewModel {
    public weak var resultDelegate: BodyCellViewModelResultDelegate?
    public weak var delegate: BodyCellViewModelDelegate?
     public private(set) var isDirty = false
    //IOS-1369: attachments go here?

    init(resultDelegate: BodyCellViewModelResultDelegate,
         initialText: String? = nil,
         initialAttributedText: NSAttributedString? = nil) {
        self.resultDelegate = resultDelegate
        //IOS-1369: set initial
    }

    public func handleTextChange(newText: String) {
//        let textOnly = newText.trimObjectReplacementCharacters().trimmed()
        isDirty = true
        resultDelegate?.bodyCellViewModel(self, textChanged: newText)
    }
}
