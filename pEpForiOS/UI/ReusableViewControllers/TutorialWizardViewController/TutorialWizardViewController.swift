//
//  TutorialWizardViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 02/09/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

class TutorialWizardViewController: UIViewController {
    
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var skipeButton: UIButton!

    static let storyboardId = "TutorialWizardViewController"

    private var viewModel = TutorialWizardViewMode()
    private var images = [UIImage]()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.delegate = self
        setUpView()
    }

    @IBAction func didPress(_ sender: UIButton) {
        switch sender.tag {
        case 1: //Setted in Storyboard
            viewModel.handle(action: .skip)
        default:
            break
        }
    }

    static func fromStoryboard(images: [UIImage]) -> TutorialWizardViewController? {
        let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
        guard let tutorialWizard = storyboard.instantiateViewController(
            withIdentifier: TutorialWizardViewController.storyboardId) as?
            TutorialWizardViewController else {
                Log.shared.errorAndCrash("Fail to instantiateViewController TutorialWizardViewController")
                return nil
        }
        tutorialWizard.images = images

        tutorialWizard.modalPresentationStyle = .overFullScreen

        return tutorialWizard
    }

    static func wizardImages() -> [UIImage] {
        return [#imageLiteral(resourceName: "pEpForIOS-Tutorial-1"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-2"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-3"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-4"), #imageLiteral(resourceName: "pEpForIOS-Tutorial-5")]
    }

    static func presentTutorialWizard(viewController: UIViewController) {
        let images = wizardImages()
        guard let tutorialWizard =
            TutorialWizardViewController.fromStoryboard(images: images) else {
                return
        }

        DispatchQueue.main.async { [weak viewController] in
            viewController?.present(tutorialWizard, animated: true, completion: nil)
        }
    }
}

// MARK: - TutorialWizardViewModeDelegate
extension TutorialWizardViewController: TutorialWizardViewModelDelegate {
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}


// MARK: - Private

extension TutorialWizardViewController {
    private func setUpView() {
        topBar.backgroundColor = .pEpGreen

        let skipButtonTitle = NSLocalizedString("Skip", comment: "Start up tutorial skip button")
        skipeButton.setTitle(skipButtonTitle, for: .normal)
        skipeButton.setTitleColor(.white, for: .normal)

        addPEPPageViewCotnroller()
    }

    private func addPEPPageViewCotnroller() {
        guard let pEpPageViewController =
            PEPPageViewController.fromStoryboard(showDots: true,
                                                 isScrollingEnable: true,
                                                 pageIndicatorTint: .pEpGray,
                                                 pageIndicatorCurrent: .black),
            let pageView = pEpPageViewController.view else {
                return
        }
        pEpPageViewController.views = tutorialViewControllers()
        addChild(pEpPageViewController)
        view.addSubview(pEpPageViewController.view)
        pEpPageViewController.didMove(toParent: self)

        pageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: pageView, attribute: .bottom, relatedBy: .equal,
                           toItem: view, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: pageView, attribute: .trailing, relatedBy: .equal,
                           toItem: view, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: pageView, attribute: .leading, relatedBy: .equal,
                           toItem: view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: pageView, attribute: .top, relatedBy: .equal,
                           toItem: topBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true

    }

    private func tutorialViewControllers() -> [TutorialViewController] {
        var result = [TutorialViewController]()
        for image in images {
            guard let tutorialViewController =
                TutorialViewController.fromStoryboard(image: image) else {
                    continue
            }
            result.append(tutorialViewController)
        }
        return result
    }
}
