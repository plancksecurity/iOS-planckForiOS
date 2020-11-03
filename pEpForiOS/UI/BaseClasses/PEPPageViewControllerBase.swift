//
//  PEPPageViewControllerBase.swift
//  pEp
//
//  Created by Alejandro Gelos on 22/08/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

/// Base class for PageViewControllers in pEp style.
/// You MUST NOT use this class without subclassing
class PEPPageViewControllerBase: UIPageViewController {

    var pageControlPageIndicatorColor: UIColor?
    var pageControlBackgroundColor: UIColor?
    var pageControlTint: UIColor?
    var showDots = false
    var isScrollEnable = false
    /// Stuff to do exactly once in viewWillAppear
    private var doOnce: (()->())?

    var views = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        doOnce = { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.dataSource = me.showDots ? self : nil //nil dataSource will hide dots and disable scrolling
            if !me.isScrollEnable {
                me.disableScrolling()
            }
            if let firstView = me.views.first { //!!!: is views.first == nil a valid case?
                me.setViewControllers([firstView],
                                      direction: .forward,
                                      animated: true,
                                      completion: nil)
            }
            me.doOnce = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isToolbarHidden = false
        doOnce?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setUpPageControl()
    }

    func goTo(index: Int) {
        let newView = views[index]
        setViewControllers([newView], direction: .forward, animated: true) {
            [weak self] completed in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.delegate?.pageViewController?(me, didFinishAnimating: true,
                                             previousViewControllers: [newView],
                                             transitionCompleted: completed)
        }
    }

    func goToNextView() {
        guard let nextView = nextView() else { return }
        setViewControllers([nextView], direction: .forward, animated: true) {
            [weak self] completed in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            me.delegate?.pageViewController?(me, didFinishAnimating: true,
                                             previousViewControllers: [nextView],
                                             transitionCompleted: completed)
        }
    }

    func goToPreviousView() {
        guard let previousView = previousView() else { return }
        setViewControllers([previousView], direction: .reverse, animated: true) {
            [weak self] completed in
            guard let me = self else {
                Log.shared.lostMySelf() 
                return
            }
            me.delegate?.pageViewController?(me, didFinishAnimating: true,
                                             previousViewControllers: [previousView],
                                             transitionCompleted: completed)
        }
    }

    func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    func isLast() -> Bool{
        guard nextView() != nil else {
            return true
        }
        return false
    }
}


// MARK: - UIPageViewControllerDataSource

extension PEPPageViewControllerBase: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController)
        -> UIViewController? {
            guard let previousView = previousView(of: viewController) else { return nil }
            return previousView
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController)
        -> UIViewController? {
            guard let nextView = nextView(of: viewController) else { return nil }
            return nextView
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return views.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex()
    }
}

// MARK: - UIPageViewControllerDelegate

extension PEPPageViewControllerBase: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        pageControl()?.currentPage = currentIndex()
    }
}

// MARK: - Private

extension PEPPageViewControllerBase {

    private func previousView(of viewController: UIViewController? = nil) -> UIViewController? {
        let currentPossition = currentIndex(of: viewController)
        guard currentPossition > 0 else { return nil }
        return views[currentPossition - 1]
    }

    private func nextView(of viewController: UIViewController? = nil) -> UIViewController? {
        let currentPossition = currentIndex(of: viewController)
        guard currentPossition < views.count - 1 else { return nil }
        return views[currentPossition + 1]
    }

    private func currentIndex(of viewController: UIViewController? = nil) -> Int {
        guard let currentView = viewControllers?.first else {
            return 0
        }
        guard let currentIndex = views.firstIndex(of: viewController ?? currentView) else {
                return 0
        }
        return currentIndex
    }

    private func disableScrolling() {
        let scrollView = view.subviews.first { $0 is UIScrollView } as? UIScrollView
        scrollView?.isScrollEnabled = false
    }

    private func setUpPageControl() {
        guard let pageControl = pageControl() else { return }
        if let pageControlPageIndicatorColor = pageControlPageIndicatorColor {
            pageControl.currentPageIndicatorTintColor = pageControlPageIndicatorColor
        }
        if let pageControlBackgroundColor = pageControlBackgroundColor {
            pageControl.backgroundColor = pageControlBackgroundColor
        }

        if let pageControlTint = pageControlTint {
            pageControl.pageIndicatorTintColor = pageControlTint
        }
    }

    private func pageControl() -> UIPageControl? {
        return view.subviews.first { $0 is UIPageControl } as? UIPageControl
    }
}
