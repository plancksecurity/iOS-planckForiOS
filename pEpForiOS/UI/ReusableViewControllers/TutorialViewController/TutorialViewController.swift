//
//  TutorialViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    static let storyboardId = "TutorialViewController"

    private var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViews()
    }

    static func fromStoryboard(image: UIImage) -> TutorialViewController? {
            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let tutorialViewController = storyboard.instantiateViewController(
                withIdentifier: TutorialViewController.storyboardId) as? TutorialViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController TutorialViewController")
                    return nil
            }

            tutorialViewController.image = image
            return tutorialViewController
    }
}


// MARK: - Private

extension TutorialViewController {
    private func setUpViews() {
        imageView.image = image
    }
}
