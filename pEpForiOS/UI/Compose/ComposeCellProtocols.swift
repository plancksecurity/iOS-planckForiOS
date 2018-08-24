//
//  MailComposerCellProtocols.swift
//  MailComposer
//
//  Created by Yves Landert on 16.11.16.
//  Copyright © 2016 appculture AG. All rights reserved.
//

import Foundation
import MessageModel

public protocol CellProtocol {
    var index: IndexPath! { get set }
    var textView: ComposeTextView! { get set }
}

public protocol ComposeCellDelegate: class {
    func textDidStartEditing(at indexPath: IndexPath, textView: ComposeTextView) // Only used by AccountCell afaics. Maybe refactor out.
    func textDidChange(at indexPath: IndexPath, textView: ComposeTextView)
    func textDidEndEditing(at indexPath: IndexPath, textView: ComposeTextView)

    func composeCell(cell: ComposeCell, didChangeEmailAddresses changedAddresses: [String],
                     forFieldType type: ComposeFieldModel.FieldType)
}

protocol MessageBodyCellDelegate: ComposeCellDelegate {
    func didStartEditing(at indexPath: IndexPath, composeTextView: ComposeMessageBodyTextView)
    func didEndEditing(at indexPath: IndexPath, composeTextView: ComposeMessageBodyTextView)
}
