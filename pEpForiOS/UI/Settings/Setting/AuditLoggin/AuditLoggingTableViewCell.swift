//
//  AuditLoggingTableViewCell.swift
//  planckForiOS
//
//  Created by Martin Brude on 6/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

protocol AuditLoggingDelegate: AnyObject {

    func auditLoggingValueDidChange(newValue: Int)
}

class AuditLoggingTableViewCell: UITableViewCell {

    public weak var delegate: AuditLoggingDelegate?
    @IBOutlet private weak var textField: ConfigurableCaretTextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        textField.becomeFirstResponder()
    }

    public func config(viewModel: AuditLoggingViewModel) {
        textField.shouldSelect = false
        textField.shouldShowCaret = false
        textField.keyboardType = .numberPad
        textField.placeholder = viewModel.placeholder
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
}

extension AuditLoggingTableViewCell {

    @objc private func textFieldDidChange() {
        guard let text = textField.text, let value = Int(text) else {
            delegate?.auditLoggingValueDidChange(newValue: 30)
            return
        }
        delegate?.auditLoggingValueDidChange(newValue: value)
    }
}

