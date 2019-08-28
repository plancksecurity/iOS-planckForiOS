//
//  PEPPageViewController.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

final class PEPPageViewController: UIPageViewController {

    private var viewModel: PEPPageViewModelProtocol
    private var pageControlBackgroundColor: UIColor?

    var views = [UIViewController]()

    static let storyboardId = "PEPPageViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        disableScrolling()

        guard let firstView = views.first else { return }
        setViewControllers([firstView], direction: .forward, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        pageControl(backgroundColor: pageControlBackgroundColor)
    }

    private override init(transitionStyle: UIPageViewController.TransitionStyle,
                          navigationOrientation: UIPageViewController.NavigationOrientation,
                          options: [UIPageViewController.OptionsKey : Any]?) {
        viewModel = PEPViewViewModel()
        super.init(transitionStyle: transitionStyle,
                   navigationOrientation: navigationOrientation,
                   options: options)
    }
    required init?(coder aDecoder: NSCoder) {
        viewModel = PEPViewViewModel()
        super.init(coder: aDecoder)
    }

    static func fromStoryboard(dotsBackground: UIColor? = nil,
                               viewModel: PEPPageViewModelProtocol = PEPViewViewModel())
        -> PEPPageViewController? {

            let storyboard = UIStoryboard(name: Constants.suggestionsStoryboard, bundle: .main)
            guard let pEpPageViewController = storyboard.instantiateViewController(
                withIdentifier: PEPPageViewController.storyboardId) as? PEPPageViewController else {
                    Log.shared.errorAndCrash("Fail to instantiateViewController PEPAlertViewController")
                    return nil
            }

            pEpPageViewController.viewModel = viewModel
            pEpPageViewController.pageControlBackgroundColor = dotsBackground

            return pEpPageViewController
    }

    func goToNextView(current: UIViewController) {
        guard let nextView = nextView(current: current) else { return }
        setViewControllers([nextView], direction: .forward, animated: true, completion: nil)
    }

    func goToPreviousView(current: UIViewController) {
        guard let previousView = previousView(current: current) else { return }
        setViewControllers([previousView], direction: .reverse, animated: true, completion: nil)
    }

    func didComplete(current: UIViewController) {
        goToNextView(current: current)
    }

    func disMiss() {
        dismiss(animated: true, completion: nil)
    }
}

extension PEPPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
        -> UIViewController? {
            guard let previousView = previousView(current: viewController) else { return nil }
            return previousView
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
        -> UIViewController? {
            guard let nextView = nextView(current: viewController) else { return nil }
            return nextView
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return views.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

// MARK: - UIPageViewControllerDelegate

extension PEPPageViewController: UIPageViewControllerDelegate {

}

// MARK: - Private

extension PEPPageViewController {
    private func previousView(current: UIViewController) -> UIViewController? {
        let currentPossition = currentIndex(current)
        guard currentPossition > 0 else { return nil }

        return views[currentPossition - 1]
    }

    private func nextView(current: UIViewController) -> UIViewController? {
        let currentPossition = currentIndex(current)
        guard currentPossition < views.count - 1 else { return nil }

        return views[currentPossition + 1]
    }

    private func currentIndex(_ current: UIViewController) -> Int {
        guard let currentIndex = views.firstIndex(of: current) else {
            return 0
        }
        return currentIndex
    }

    private func disableScrolling() {
        let scrollView = view.subviews.first { $0 is UIScrollView } as? UIScrollView
        scrollView?.isScrollEnabled = false
    }

    private func pageControl(backgroundColor: UIColor?) {
        guard let backgroundColor = backgroundColor else { return }
        let pageIndicatorView = view.subviews.first { $0 is UIPageControl } as? UIPageControl
        pageIndicatorView?.backgroundColor = backgroundColor
    }
}
