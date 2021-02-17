//
//  MiscUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 27/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//
import Foundation

open class MiscUtil {

    public static func isEmptyString(_ s: String?) -> Bool {
        if s == nil {
            return true
        }
        if s?.count == 0 {
            return true
        }
        return false
    }

    public static func isUnitTest() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    public static func loadData(bundleClass: AnyClass, fileName: String) -> Data? {
        let testBundle = Bundle(for: bundleClass)
        guard let keyPath = testBundle.path(forResource: fileName, ofType: nil) else {
            return nil
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: keyPath)) else {
            return nil
        }
        return data
    }
}
