//
//  NSManagedObject+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.06.17.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    public func allPropertyNames() -> [String] {
        let properties = entity.properties.map { return $0.name }
        return properties
    }
}
