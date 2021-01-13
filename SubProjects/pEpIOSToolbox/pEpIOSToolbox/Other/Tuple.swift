//
//  Tuple.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15.05.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

struct Tuple<T:Hashable, U:Hashable>: Hashable {
    let values : (T, U)

    func hash(into hasher: inout Hasher) {
        let (a,b) = values
        hasher.combine(a)
        hasher.combine(b)
    }
}

extension Tuple: Equatable {
    static func ==<T, U>(lhs: Tuple<T,U>, rhs: Tuple<T,U>) -> Bool {
        return lhs.values == rhs.values
    }
}
