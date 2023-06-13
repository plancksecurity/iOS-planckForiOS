//
//  AuditLogginTableViewCell.swift
//  planckForiOS
//
//  Created by Martin Brude on 6/6/23.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox

protocol AuditLogginDelegate: AnyObject {

    func auditLogginValueDidChange(newValue: Double)
}

class AuditLogginTableViewCell: UITableViewCell {

    @IBOutlet weak var textField: ConfigurableCaretTextField!
    
    weak var delegate: AuditLogginDelegate?

    public func config(viewModel: AuditLoginViewModel) {
        textField.shouldSelect = false
        textField.shouldShowCaret = false
        textField.keyboardType = .numberPad
        textField.placeholder = viewModel.placeholder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
            self.textField.becomeFirstResponder()
        }
        
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

    }
}

extension AuditLogginTableViewCell {

    @objc func textFieldDidChange() {
        guard let text = textField.text, let value = Double(text) else {
            delegate?.auditLogginValueDidChange(newValue: 1)
            return
        }
        delegate?.auditLogginValueDidChange(newValue: value)
    }
}

