//
//  CustomTraitCollectionViewController.swift
//  pEp
//
//  Created by Martin Brude on 03/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Handles size classes for iPad properly.
///
/// As they don’t cover the difference between iPad Portrait and Landscape:
/// they both have Regular Width and Regular Height.
///
/// Generates for iPad in Portrait the same behavior as iPhone in Portrait (compact, regular).
/// Known issue: Storyboard will not reflect this.
/// To modify constraints for iPad portrait without affecting iPhone Portrait,
/// we must affect only those iPad contraints throught IBOutlets.
public class CustomTraitCollectionViewController: UIViewController {
    
    /// The traits of the current view controller and its descendants classes.
    override public var traitCollection: UITraitCollection {
        //Only for ipad portrait a custom trait collection is set.
        if UIDevice.isIpad && !UIDevice.isLandscape {
            let compact = UITraitCollection(horizontalSizeClass: .compact)
            let regular = UITraitCollection(verticalSizeClass: .regular)
            return UITraitCollection(traitsFrom: [compact, regular])
        }
        return super.traitCollection
    }
}
