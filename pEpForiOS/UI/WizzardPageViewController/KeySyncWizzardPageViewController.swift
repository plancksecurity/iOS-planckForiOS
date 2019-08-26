//
//  KeySyncWizzardPageViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class WizzardPageViewController: UIPageViewController {

    private var viewModel: WizzardViewModelProtocol

    static let storyboardId = "WizzardPageViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

//        dataSource = self
//        delegate = self
    }

    private override init(transitionStyle: UIPageViewController.TransitionStyle,
                 navigationOrientation: UIPageViewController.NavigationOrientation,
                 options: [UIPageViewController.OptionsKey : Any]?) {
        viewModel = WizzardViewModel()
        super.init(transitionStyle: transitionStyle,
                   navigationOrientation: navigationOrientation,
                   options: options)
    }
    required init?(coder aDecoder: NSCoder) {
        viewModel = WizzardViewModel()
        super.init(coder: aDecoder)
    }

    static func fromStoryboard(withViews views: [UIViewController],
                               showDots: Bool? = true,
                               viewModel: WizzardViewModelProtocol = WizzardViewModel())
        -> WizzardPageViewController? {

            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let wizzardPageViewController = storyboard.instantiateViewController(
                withIdentifier: PEPAlertViewController.storyboardId) as? WizzardPageViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController WizzardPageViewController")
                    return nil
            }

            wizzardPageViewController.viewModel = viewModel
//            wizzardPageViewController.viewModel.delegate = pEpAlertViewController

            wizzardPageViewController.setViewControllers(views,
                                                         direction: .forward,
                                                         animated: true,
                                                         completion: nil)

            return wizzardPageViewController
    }
}

//extension WizzardPageViewController: UIPageViewControllerDataSource {
//    func pageViewController(_ pageViewController: UIPageViewController,
//                            viewControllerBefore viewController: UIViewController)
//        -> UIViewController? {
//
//
//    }
//
//    func pageViewController(_ pageViewController: UIPageViewController,
//                            viewControllerAfter viewController: UIViewController)
//        -> UIViewController? {
//
//    }
//}
