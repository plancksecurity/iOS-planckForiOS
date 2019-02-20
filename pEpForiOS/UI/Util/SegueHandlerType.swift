//
//  SegueHandlerType.swift
//
//  Pattern for using segues via enumeration.
//  see: https://developer.apple.com/videos/wwdc/2015/?id=411
//
//  Created by Marko Tadic on 8/25/15.
//  Copyright © 2015 AE. All rights reserved.
//

import UIKit

public protocol SegueHandlerType {
    associatedtype SegueIdentifier: RawRepresentable
}

public extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    public func performSegue(withIdentifier identifier: SegueIdentifier, sender: Any?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
    
    public func segueIdentifier(for segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let
            identifier = segue.identifier,
            let segueIdentifier = SegueIdentifier(rawValue: identifier)
        else {
            return SegueIdentifier(rawValue: "noSegue")!
        }
        return segueIdentifier
    }
}
