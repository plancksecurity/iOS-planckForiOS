//
//  TutorialStepViewController.swift
//  pEp
//
//  Created by Martin Brude on 02/03/2020.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation


// This class MUST be inherited. Do not use it directly.
class TutorialStepViewController: CustomTraitCollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    var centered : NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = -2
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
            return UIFont.systemFont(ofSize: 25.0, weight: .regular)
        } else if Device.isIphone5 {
            return UIFont.systemFont(ofSize: 12.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 14.0, weight: .regular)
    }

    var titleFont : UIFont {
        if isIpad {
            return UIFont.systemFont(ofSize: 45.0, weight: .regular)
        } else if Device.isIphone5 {
            return UIFont.systemFont(ofSize: 21.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 28.0, weight: .regular)
    }
    
    var subtitleFont : UIFont {
        if isIpad {
            return UIFont.systemFont(ofSize: 38.0, weight: .regular)
        } else if Device.isIphone5 {
            return UIFont.systemFont(ofSize: 21.0, weight: .regular)
        }
        return UIFont.systemFont(ofSize: 20.0, weight: .regular)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
//        guard let childern = parent?.children as? [TutorialStepViewController] else { return }
//        _ = childern.map { $0.configureView() }
    }

    /// Abstract method to be overriden
    /// This method MUST configure aspects of the layout of the view that can not be configured in storyboard.
    public func configureView() {
        Log.shared.errorAndCrash("This method must be overriden")
    }

    /// Util class to detect if the device is an iPhone 5
    private struct Device {
        private static let isIphone = UIDevice.current.userInterfaceIdiom == .phone
        private static let screenWidth = Int(UIScreen.main.bounds.size.width)
        private static let screenHeight = Int(UIScreen.main.bounds.size.height)
        private static let screenMaxLength = Int(max(screenWidth, screenHeight))
        private static let SCREEN_MIN_LENGTH = Int(min(screenWidth, screenHeight))
        static let isIphone5 = isIphone && screenMaxLength == 568 // 5, 5S, 5C, SE
    }
}
