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

    typealias TutorialImage = (portrait: UIImage, landscape: UIImage?)

    static let storyboardId = "TutorialViewController"
    private var landscapeImage: UIImage?
    private var portraitImages: UIImage?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setUpViews()
    }

    static func fromStoryboard(tutorialImage: TutorialImage) -> TutorialViewController? {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
        guard let tutorialViewController = storyboard.instantiateViewController(
            withIdentifier: TutorialViewController.storyboardId) as? TutorialViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController TutorialViewController")
                return nil
        }

        tutorialViewController.portraitImages = tutorialImage.portrait
        tutorialViewController.landscapeImage = tutorialImage.landscape
        return tutorialViewController
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        setUpViews()
    }
}


// MARK: - Private

extension TutorialViewController {
    private func setUpViews() {
        if UIApplication.shared.statusBarOrientation.isLandscape,
            let landscapeImage = landscapeImage {
            imageView.image = landscapeImage
        } else {
            imageView.image = portraitImages
        }
    }
}
