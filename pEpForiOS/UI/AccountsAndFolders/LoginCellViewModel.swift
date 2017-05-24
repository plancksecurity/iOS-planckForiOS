//
//  LoginCellViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 23/05/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

public enum LoginCellType {
    case Username, Email, Password, Error, Login, ManualConfiguration
}

public class LoginCellViewModel {

    var title: String
    var textColor: UIColor
    public init (type: LoginCellType) {
        title = "lalala"
        textColor = UIColor.red
    }
}
