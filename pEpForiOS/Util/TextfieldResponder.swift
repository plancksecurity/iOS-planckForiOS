//
//  TextfieldResponder.swift
//  pEpForiOS
//
//  Created by Yves Landert on 02.11.16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

protocol TextfieldResponder: AnyObject {
    
    var fields: [UITextField] { get set }
    var responder: Int { get set }
    
    func firstResponder(_ condtition: Bool)
    func nextResponder(_ textfield: UITextField)
    func changedResponder(_ textfield: UITextField)
}

extension TextfieldResponder {
    
    public func firstResponder(_ condition: Bool) {
        fields[responder].resignFirstResponder()
        if condition {
            fields.first?.becomeFirstResponder()
        }
    }
    
    public func nextResponder(_ textfield: UITextField) {
        responder += 1
        if responder < fields.count && textfield == fields[responder - 1] {
            fields[responder].becomeFirstResponder()
        } else {
            responder = 0
            fields[responder].becomeFirstResponder()
        }
    }
    
    public func changedResponder(_ textfield: UITextField) {
        for (i, field) in fields.enumerated() {
            if field == textfield {
                responder = i
            }
        }
    }
}
