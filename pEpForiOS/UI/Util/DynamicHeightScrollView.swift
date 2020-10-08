//
//  DynamicHeightScrollView.swift
//  pEp
//
//  Created by Alejandro Gelos on 21/11/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import UIKit

import pEpIOSToolbox

protocol DynamicHeightScrollViewDelegate: class {
    /// Bottom constraint of the scroll view. Used to change the hegiht of the scrollView, modifying the constant
    var bottomConstraint: NSLayoutConstraint { get }
    /// Current  scrollView subViews first responder that will be center
    var firstResponder: UIView? { get }
}

// Did not crate a nested class for DynamicHeightScrollView, since its not visible from Interface builder
@IBDesignable
/// Use this ScrollView to keep the first responder (typically TextFeilds) centered in the scrollView
final class DynamicHeightScrollView: UIScrollView {

    /// Use this property to enable/disable auto scroll to make visible, the firstResponder when editing or start editing
    @IBInspectable var makeVisibleAutoScroll: Bool = false

    /// Use this delegate to give the scrollView information to be able to center the firstResponder
    public weak var dynamicHeightScrollViewDelegate: DynamicHeightScrollViewDelegate?

    override func awakeFromNib() {
        configureKeyboardAwareness()
    }

    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        guard makeVisibleAutoScroll else { return }
        super.scrollRectToVisible(rect, animated: animated)
    }

    /// Use this funtion to center a first responder subview of the ScrollView
    /// - Parameters:
    ///   - sender: current first responder
    ///   - animated: enable/disable animating scrolling to center first responder
    func scrollAndMakeVisible(_ sender: UIView,
                              animated: Bool = true) {
        let scrollViewHeight = frame.maxY
        let senderFrames = sender.convert(sender.bounds, to: self)
        var newContentOffSet = senderFrames.midY - scrollViewHeight / 2
        let contetOffSetDistanceToSafeArea =
            contentSize.height - newContentOffSet - scrollViewHeight

        //Add padding if can not scroll enough
        if newContentOffSet < 0 {
            contentInset.top = abs(newContentOffSet)
        } else if contetOffSetDistanceToSafeArea < 0 {
            contentInset.bottom = abs(contetOffSetDistanceToSafeArea)
            newContentOffSet = contentSize.height
                - scrollViewHeight
                + abs(contetOffSetDistanceToSafeArea)
        }

        setContentOffset(CGPoint(x: 0, y: newContentOffSet), animated: animated)
    }
}

// MARK: - Private

extension DynamicHeightScrollView {
    private func configureKeyboardAwareness() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateScrollViewToHideyboard),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateScrollViewToShowKeyboard),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    @objc private func updateScrollViewToHideyboard(notification: NSNotification) {
        contentInset.bottom = 0
        contentInset.top = 0
        adjustScrollViewHeight(notification: notification)
    }

    @objc private func updateScrollViewToShowKeyboard(notification: NSNotification) {
        adjustScrollViewHeight(notification: notification)
        centerFirstResponder(notification: notification)
    }

    private func keyBoardHeight(notification: NSNotification) -> CGFloat {
        guard notification.name == UIResponder.keyboardWillShowNotification,
            let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                //Keyboard is hidding, move view to original center
                return 0
        }

        return keyboardValue.cgRectValue.height
    }

    private func keyBoardAnimationDuration(notification: NSNotification) -> Double? {
        guard let duration =
            notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return nil
        }
        return duration
    }

    private func adjustScrollViewHeight(notification: NSNotification) {
        guard let bottomConstraint = dynamicHeightScrollViewDelegate?.bottomConstraint else {
            Log.shared.errorAndCrash("DynamicHeightScrollView delegate is nil")
            return
        }
        var bottomSafeArea: CGFloat = 0
        if let window = window {
            bottomSafeArea = window.safeAreaInsets.bottom
        }

        bottomConstraint.constant = -keyBoardHeight(notification: notification) + bottomSafeArea

        guard let animationDuration = keyBoardAnimationDuration(notification: notification) else {
            Log.shared.errorAndCrash("Fail to get keyboard animation duration")
            layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
                        guard let me = self else {
                            Log.shared.lostMySelf()
                            return
                        }
                        me.superview?.layoutIfNeeded()
        })
    }

    private func centerFirstResponder(notification: NSNotification) {
        guard let firstResponder = dynamicHeightScrollViewDelegate?.firstResponder else {
            //If no firstReponder, then just center the stack view
            scrollToCenterStackView()
            return
        }
        scrollAndMakeVisible(firstResponder)
    }

    private func scrollToCenterStackView() {
        guard let superView = superview else {
            Log.shared.errorAndCrash("Fail to get DynamicHeightScrollView superView")
            return
        }
        let newContentOffSet = (superView.bounds.height - bounds.height) / 2
        DispatchQueue.main.async { [weak self] in
            self?.setContentOffset(CGPoint(x: 0, y: newContentOffSet), animated: true)
        }
    }
}

