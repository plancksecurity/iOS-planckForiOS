//
//  commonFunc.swift
//  planckForiOSUITests
//
//  Created by Nasr on 10/06/2023.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
class commonFunc {
    func generateRandomBot() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<5).map { _ in letters.randomElement()! })
        return randomString + "@sq.planck.security"
    }
}
