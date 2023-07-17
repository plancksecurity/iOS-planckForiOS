//
//  commonFunc.swift
//  planckForiOSUITests
//
//  Created by Nasr on 10/06/2023.
//  Copyright © 2023 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
class CommonFunctions {
    
    let app = XCUIApplication()
    
    func appLaunch(){
        app.launch()
    }
    
    func appTerminate(){
        app.terminate()
    }
    
    func generateRandomBot() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<5).map { _ in letters.randomElement()! })
        return randomString + "@demo.planck.dev"
    }
}
