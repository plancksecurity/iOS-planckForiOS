//
//  NSPredicate+PredicateFactory.swift
//  MessageModel
//
//  Created by Adam Kowalski on 23/04/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    public struct Query {
        public struct PredicateFactory {
            static public func predicateForAttributes(key: AnyHashable,
                                                      value: Any) -> NSPredicate {
                return NSPredicate(format: "%K = %@", argumentArray: [key, value])
            }
        }
    }
}
