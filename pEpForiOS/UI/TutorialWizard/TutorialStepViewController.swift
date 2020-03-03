//
//  TutorialStepViewController.swift
//  pEp
//
//  Created by Martin Brude on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

class TutorialStepViewController: UIViewController {
    var centered : NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }
    
    var spaced : NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 6
        return paragraphStyle
    }
    
    var textAttributes : [NSAttributedString.Key : Any] {
        return [
          .font: font,
          .foregroundColor: UIColor(white: 24.0 / 255.0, alpha: 1.0),
          .paragraphStyle: centered,
        ]
    }
    
    var font : UIFont {
        if isIpad {
//            if isLandscape {
                return UIFont.systemFont(ofSize: 25.0, weight: .regular)
//            }
//            return UIFont.systemFont(ofSize: 21.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 14.0, weight: .regular)
    }
    
    var titleFont : UIFont {
        if isIpad {
//            if isLandscape {
                return UIFont.systemFont(ofSize: 45.0, weight: .regular)
//            }
//            return UIFont.systemFont(ofSize: 38.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 28.0, weight: .regular)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        configureView()
    }
    
    /// Abstract method to be overriden
    /// This method MUST configure aspects of the layout of the view that can not be configured in storyboard.
    public func configureView() { }
}
