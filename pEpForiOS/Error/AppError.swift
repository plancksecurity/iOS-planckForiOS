//
//  AppError.swift
//  pEp
//
//  Created by Alejandro Gelos on 07/06/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

struct AppError {
    enum Storyboard: Error {
        case failToInitViewController
    }

    enum General: Error {
        case noAppConfig
    }
}
