//
//  Collection+Extensions.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 11/10/16.
//  Copyright © 2016 pEp Security S.A. All rights reserved.
//

extension Collection {
    /*
     * Returns the element at the specified index if it is within bounds, otherwise nil.
     */
    public subscript(safe index: Index) -> Iterator.Element? {
        return index >= startIndex && index < endIndex ? self[index] : nil
    }
}
