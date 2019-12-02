//
//  AccountTypeSelectorViewModel.swift
//  pEp
//
//  Created by Xavier Algarra on 02/12/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum Providers {
    case GMail
    case Other
}

class AccountTypeSelectorViewModel {

    var providers = [Providers]()
    init() {
        providers.append(.GMail)
        providers.append(.Other)
    }

    var count: Int {
        get {
            return providers.count
        }
    }

    subscript(index: Int) -> String {
        //Missing implementation choos if give back the image or some id
        return ""
    }



}
