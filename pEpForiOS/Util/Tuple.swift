//
//  Tuple.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

struct Tuple<T:Hashable, U:Hashable>: Hashable {
    let values : (T, U)

    var hashValue : Int {
        get {
            let (a,b) = values
            return a.hashValue &* 31 &+ b.hashValue
        }
    }
}

extension Tuple: Equatable {
    static func ==<T:Hashable, U:Hashable>(lhs: Tuple<T,U>, rhs: Tuple<T,U>) -> Bool {
        return lhs.values == rhs.values
    }
}
