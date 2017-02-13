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
    weak var textView: ComposeTextView! { get set }
}

public protocol ComposeCellDelegate: class {
    func textdidStartEditing(at indexPath: IndexPath, textView: ComposeTextView)
    func textdidChange(at indexPath: IndexPath, textView: ComposeTextView)
    func textDidEndEditing(at indexPath: IndexPath, textView: ComposeTextView)
    func textShouldReturn(at indexPath: IndexPath, textView: ComposeTextView)
    func haveToUpdateColor(newIdentity: [Identity], type: ComposeFieldModel)
    func fromAccountChanged(newIdentity: Identity, type: ComposeFieldModel)
}

public protocol RecipientCellDelegate: ComposeCellDelegate {
    
    func shouldOpenAddressbook(at indexPath: IndexPath)
}

public protocol MessageBodyCellDelegate: ComposeCellDelegate {
    
    func didStartEditing(at indexPath: IndexPath)
    func didEndEditing(at indexPath: IndexPath)
}
