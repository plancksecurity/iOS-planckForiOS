//
//  Appearance.swift
//  pEpForiOS
//
//  Created by Igor Vojinovic on 1/19/17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import UIKit

class Appearance {
    
    static func standard() {

        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = .black
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.white]
        
        UIToolbar.appearance().backgroundColor = .white
        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = .black
        
        UITextView.appearance().tintColor = .black
        UITextField.appearance().tintColor = .black
        
        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().backgroundColor = .black
        UISearchBar.appearance().tintColor = .black
    }
    
    static func pep(_ color: UIColor = .pEpGreen) {
        
        UINavigationBar.appearance().backgroundColor = color
        UINavigationBar.appearance().barTintColor = color
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSForegroundColorAttributeName: UIColor.white]
        
        UIToolbar.appearance().backgroundColor = color
        UIToolbar.appearance().barTintColor = color
        UIToolbar.appearance().tintColor = .white
        
        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color
        
        UISearchBar.appearance().barTintColor = color
        UISearchBar.appearance().backgroundColor = color
        UISearchBar.appearance().tintColor = .white
    }
}
