//
//  Constants.swift
//  PEPLogger
//
//  Created by Alejandro Gelos on 31/01/2020.
//  Copyright © 2020 Alejandro Gelos. All rights reserved.
//

import Foundation

struct Constants {
    // Max log file size
    let maxFileSize: UInt64 = 2048

    enum LoggingError: Error, LocalizedError {
        case nilFileURL, nilDataFromString

        var errorDescription: String? {
            switch self {
            case .nilFileURL:
                return "Fail to get file URL"
            case .nilDataFromString :
                return "Fail to conver String to Data"
            }
        }
    }

    
}
