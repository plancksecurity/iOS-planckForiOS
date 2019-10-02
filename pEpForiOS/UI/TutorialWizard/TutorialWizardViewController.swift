//
//  TutorialWizardViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class TutorialWizardViewController: PEPPageViewController {

    private var viewModel = TutorialWizardViewMode()
    private var tutorialImages = [TutorialViewController.TutorialImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }

    static func fromStoryboard(tutorialImages: [TutorialViewController.TutorialImage])
        -> TutorialWizardViewController? {
            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let tutorialWizard = storyboard.instantiateViewController(
                withIdentifier: PEPPageViewController.storyboardId) as?
                TutorialWizardViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController TutorialWizardViewController")
                    return nil
            }
            tutorialWizard.tutorialImages = tutorialImages

            tutorialWizard.modalPresentationStyle = .overFullScreen

            return tutorialWizard
    }

    static func wizardImages() -> [TutorialViewController.TutorialImage] {
        let view_1:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-1", comment: "TutorialWizard image 1")), #imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-1-horizontal", comment: "TutorialWizard image 1 horizontal")))
        let view_2:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-2", comment: "TutorialWizard image 2")), #imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-2-horizontal", comment: "TutorialWizard image 2 horizontal")))
        let view_3:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-3", comment: "TutorialWizard image 3")), #imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-3-horizontal", comment: "TutorialWizard image 3 horizontal")))
        let view_4:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-4", comment: "TutorialWizard image 4")), #imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-4-horizontal", comment: "TutorialWizard image 4 horizontal")))
        let view_5:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-5", comment: "TutorialWizard image 5")), #imageLiteral(resourceName: NSLocalizedString("pEpForIOS-Tutorial-5-horizontal", comment: "TutorialWizard image 5 horizontal")))
        return [view_1, view_2, view_3, view_4, view_5]
    }

    static func presentTutorialWizard(viewController: UIViewController) {
        let tutrialImages = wizardImages()
        guard let tutorialWizard =
            TutorialWizardViewController.fromStoryboard(tutorialImages: tutrialImages) else {
                return
        }

        tutorialWizard.isScrollEnable = true
        tutorialWizard.showDots = true
        tutorialWizard.pageControlTint = .pEpGray
        tutorialWizard.pageControlPageIndicatorColor = .black

        let navigationController = UINavigationController(rootViewController: tutorialWizard)

        DispatchQueue.main.async { [weak viewController] in
            viewController?.present(navigationController, animated: true, completion: nil)
        }
    }
}

// MARK: - Private

extension TutorialWizardViewController {
    private func setUpView() {
        views = tutorialViewControllers()
        //aqui seteamos el boton de la nav y lo canviamos como toca cuando toca
//        topBar.backgroundColor = .pEpGreen
//
//        let skipButtonTitle = NSLocalizedString("Finish", comment: "Start up tutorial finish button")
//        skipeButton.setTitle(skipButtonTitle, for: .normal)
//        skipeButton.setTitleColor(.white, for: .normal)

        //addPEPPageViewCotnroller()
    }

//    private func addPEPPageViewCotnroller() {
//        guard let pEpPageViewController =
//            PEPPageViewController.fromStoryboard(showDots: true,
//                                                 isScrollingEnable: true,
//                                                 pageIndicatorTint: .pEpGray,
//                                                 pageIndicatorCurrent: .black),
//            let pageView = pEpPageViewController.view else {
//                return
//        }
//        pEpPageViewController.views = TutorialWizardViewController.tutorialViewControllers()
//        //self.presentViewController(navigationController, animated: true, completion: nil)
//        addChild(pEpPageViewController)
//        view.addSubview(pEpPageViewController.view)
//        pEpPageViewController.didMove(toParent: self)
//
//        pageView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint(item: pageView, attribute: .bottom, relatedBy: .equal,
//                           toItem: view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//        NSLayoutConstraint(item: pageView, attribute: .trailing, relatedBy: .equal,
//                           toItem: view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
//        NSLayoutConstraint(item: pageView, attribute: .leading, relatedBy: .equal,
//                           toItem: view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
//        NSLayoutConstraint(item: pageView, attribute: .top, relatedBy: .equal,
//                           toItem: topBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
//
//    }

    private func tutorialViewControllers() -> [TutorialViewController] {
        var result = [TutorialViewController]()
        for tutorialImage in tutorialImages {
            guard let tutorialViewController =
                TutorialViewController.fromStoryboard(tutorialImage: tutorialImage) else {
                    continue
            }
            result.append(tutorialViewController)
        }
        return result
    }
}
