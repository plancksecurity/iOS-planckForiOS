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
            [NSAttributedStringKey.foregroundColor: UIColor.black]
        
        UIToolbar.appearance().backgroundColor = .white
        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = .black
        
        UITextView.appearance().tintColor = .black
        UITextField.appearance().tintColor = .black
        
        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().backgroundColor = .black
        UISearchBar.appearance().tintColor = .black
    }
    
    static func pEp(_ color: UIColor = .pEpGreen) {
        UINavigationBar.appearance().backgroundColor = color
        UINavigationBar.appearance().barTintColor = color
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSAttributedStringKey.foregroundColor: UIColor.white]
        
        UIToolbar.appearance().backgroundColor = color
        UIToolbar.appearance().barTintColor = color
        UIToolbar.appearance().tintColor = .white
        
        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color
        
        UISearchBar.appearance().barTintColor = color
        UISearchBar.appearance().backgroundColor = color
        UISearchBar.appearance().tintColor = .white
    }

    static func pEpPale(_ color: UIColor = .pEpGreen) {
        UINavigationBar.appearance().backgroundColor = .white
        UINavigationBar.appearance().barTintColor = .white
        UINavigationBar.appearance().tintColor = color
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().titleTextAttributes =
            [NSAttributedStringKey.foregroundColor: UIColor.white]

        UIToolbar.appearance().backgroundColor = .white
        UIToolbar.appearance().barTintColor = .white
        UIToolbar.appearance().tintColor = color

        UITextView.appearance().tintColor = color
        UITextField.appearance().tintColor = color

        UISearchBar.appearance().barTintColor = .white
        UISearchBar.appearance().backgroundColor = .white
        UISearchBar.appearance().tintColor = color
    }
}
