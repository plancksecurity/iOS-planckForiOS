//
//  DeviceUtils.swift
//  pEp
//
//  Created by Martin Brude on 07/07/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation


public struct DeviceUtils {
    private static let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    private static let screenWidth = Int(UIScreen.main.bounds.size.width)
    private static let screenHeight = Int(UIScreen.main.bounds.size.height)
    private static let screenMaxLength = Int(max(screenWidth, screenHeight))
    private static let SCREEN_MIN_LENGTH = Int(min(screenWidth, screenHeight))
    static let isIphone5 = isIphone && screenMaxLength == 568 // 5, 5S, 5C, SE

}
