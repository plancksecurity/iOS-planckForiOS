//
//  XCTest+Extension.swift
//  pEpForiOSTests
//
//  Created by Martín Brude on 25/11/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest
import pEpIOSToolbox

extension XCTestCase {

    /// Loads the file and retrive its data.
    /// - Parameters:
    ///   - name: The name of the file
    ///   - fileExtension: The file extension
    /// - Returns: The data if doesnt fail. In case it does, check the target of the file.
    func loadFile(withName name: String, withExtension fileExtension: String) -> Data? {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: name, withExtension: fileExtension) else {
            Log.shared.error("File not found.")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            Log.shared.error("Data not found.")
            return nil
        }
        return data
    }
}
