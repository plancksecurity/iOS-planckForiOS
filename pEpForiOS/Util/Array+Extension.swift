//
//  Array+Extension.swift
//  pEpForiOS
//
//  Created by Yves Landert on 07.12.16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

extension Array {
    
    func isSafe(_ index: Int) -> Any? {
        return indices ~= index ? self[index] : nil
    }
}
