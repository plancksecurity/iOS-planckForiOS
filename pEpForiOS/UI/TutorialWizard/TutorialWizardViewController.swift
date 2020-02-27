//
//  TutorialWizardViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class TutorialWizardViewController: PEPPageViewControllerBase {
    static let storyboardId = "TutorialWizardViewController"
    private var viewModel = TutorialWizardViewMode()
    private var tutorialImages = [TutorialViewController.TutorialImage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()

        if #available(iOS 13, *) {
            Appearance.customiseForTutorial(viewController: self)
        }
    }

    static func fromStoryboard(tutorialImages: [TutorialViewController.TutorialImage])
        -> TutorialWizardViewController? {
            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let tutorialWizard = storyboard.instantiateViewController(
                withIdentifier: storyboardId) as?
                TutorialWizardViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController TutorialWizardViewController")
                    return nil
            }
            tutorialWizard.tutorialImages = tutorialImages

            tutorialWizard.modalPresentationStyle = .overFullScreen

            return tutorialWizard
    }

    static func wizardImages() -> [TutorialViewController.TutorialImage] {
        let view_1:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: "pEpForIOS-Tutorial-vertical-1"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-horizontal-1"))
        let view_2:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: "pEpForIOS-Tutorial-vertical-2"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-horizontal-2"))
        let view_3:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: "pEpForIOS-Tutorial-vertical-3"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-horizontal-3"))
        let view_4:TutorialViewController.TutorialImage = (#imageLiteral(resourceName: "pEpForIOS-Tutorial-vertical-4"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-horizontal-4"))
        return [view_1, view_2, view_3, view_4]
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
        tutorialWizard.pageControlBackgroundColor = .white

        let navigationController = UINavigationController(rootViewController: tutorialWizard)

        DispatchQueue.main.async { [weak viewController] in
            navigationController.modalPresentationStyle = .fullScreen
            viewController?.present(navigationController, animated: true, completion: nil)
        }
    }

    @objc func closeScreen() {
        dismiss(animated: true)
    }

    func updateNavButton(lastScreen: Bool) {
        var navBarButtonTitle = ""
        if lastScreen {
            navBarButtonTitle = NSLocalizedString("Finish",
                                                  comment: "Start up tutorial finish button")
        } else {
            navBarButtonTitle = NSLocalizedString("Skip",
                                                  comment: "Start up tutorial skip button")
        }
        let endButton = UIBarButtonItem(title: navBarButtonTitle, style: .done, target: self, action: #selector(closeScreen))
        self.navigationItem.rightBarButtonItem  = endButton
    }

    override func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        super.pageViewController(pageViewController, didFinishAnimating: finished, previousViewControllers: previousViewControllers, transitionCompleted: completed)
        updateNavButton(lastScreen: isLast())
    }
}

// MARK: - Private

extension TutorialWizardViewController {
    private func setUpView() {
        views = tutorialViewControllers()
        view.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = .pEpGreen
        navigationController?.navigationBar.tintColor = .white
        updateNavButton(lastScreen: false)
    }

    //Staring point
    private func tutorialViewControllers() -> [TutorialViewController] {
        var result = [TutorialViewController]()
        
        for (index, tutorialImage) in tutorialImages.enumerated() {
            guard let tutorialViewController =
                TutorialViewController.fromStoryboard(tutorialImage: tutorialImage) else {
                    continue
            }
            result.append(tutorialViewController)

        }
//        for tutorialImage in tutorialImages {
//            guard let tutorialViewController =
//                TutorialViewController.fromStoryboard(tutorialImage: tutorialImage) else {
//                    continue
//            }
//            result.append(tutorialViewController)
//        }
        return result
    }
}


extension TutorialViewController {
    
    private func assetName(step : Int) -> String {
        let currentLanguageCode = Locale.current.languageCode ?? "en"
        isL
        "pEpForIOS-Tutorial-portrait-\(1)-\(currentLanguageCode)"
        
//        pEpForIOS-Tutorial-portrait-1-en
        return ""
    }
}
