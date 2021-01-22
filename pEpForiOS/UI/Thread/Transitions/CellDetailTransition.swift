// Message threadding is currently umsupported. The code might be helpful.

////
////  CellDetailTransition.swift
////  pEp
////
////  Created by Miguel Berrocal Gómez on 28/06/2018.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import Foundation
//
//class CellDetailTransition: NSObject, UIViewControllerAnimatedTransitioning {
//
//    let duration: TimeInterval
//    let isDismissing: Bool
//
//    init(duration: TimeInterval, isDismissing: Bool = false) {
//        self.duration = duration
//        self.isDismissing = isDismissing
//    }
//
//    func transitionDuration(
//        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
//        return duration
//    }
//
//    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
//        if !isDismissing {
//            animatePush(using: transitionContext)
//        } else {
//            animatePop(using: transitionContext)
//        }
//    }
//
//    private func animatePush(using transitionContext: UIViewControllerContextTransitioning) {
//        let containerView = transitionContext.containerView
//
//        guard let fromView = transitionContext.view(forKey: .from),
//            let toView = transitionContext.view(forKey: .to),
//            let fromViewController = transitionContext.viewController(forKey: .from),
//            let tableView = (fromViewController as? ThreadViewController)?.tableView ,
//            let selectedIndexPath = tableView.indexPathForSelectedRow,
//            let cell = tableView.cellForRow(at: selectedIndexPath),
//            let fullCell = cell as? FullMessageCell else {
//                return
//        }
//
//        tableView.bringSubviewToFront(cell)
//
//        let fromCellView:UIView = fullCell.roundedView
//        let originalFrame = fromCellView.frame
//
//        var fromFrame: CGRect!
//        var toFrame = toView.frame
//
//        fromFrame = containerView.convert(fromCellView.frame, from: cell)
//        toView.frame = fromFrame
//        toView.alpha = 0
//
//        containerView.addSubview(toView)
//
//        UIView.animate(withDuration: 0.4, animations: {
//            fromCellView.frame = containerView.convert(toFrame, to: fromCellView)
//            fromCellView.frame.origin.x = 0
//            toView.frame = toFrame
//            toView.alpha = 1
//            fromView.alpha = 0
//        }) { (completed) in
//            fromCellView.frame = originalFrame
//            fromView.alpha = 1
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//        }
//    }
//
//    private func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
//        let containerView = transitionContext.containerView
//
//        guard let fromView = transitionContext.view(forKey: .from),
//            let toView = transitionContext.view(forKey: .to),
//            let toViewController = transitionContext.viewController(forKey: .to),
//            let tableView = (toViewController as? ThreadViewController)?.tableView,
//            let selectedIndexPath = tableView.indexPathForSelectedRow,
//            let cell = tableView.cellForRow(at: selectedIndexPath),
//            let fullCell = cell as? FullMessageCell else {
//                return
//        }
//
//        tableView.bringSubviewToFront(cell)
//
//        let toCellView:UIView = fullCell.roundedView
//        let originalFrame = toCellView.frame
//
//        var toFrame: CGRect!
//
//        toCellView.alpha = 0
//        toView.alpha = 0
//
//        containerView.insertSubview(toView, belowSubview: fromView)
//        toFrame = containerView.convert(toCellView.frame, from: cell)
//        toCellView.frame = containerView.convert(fromView.frame, to: toCellView)
//        toCellView.frame.origin.x = 0
//
//        UIView.animate(withDuration: 0.4, animations: {
//            fromView.frame = toFrame
//            toCellView.frame = originalFrame
//            fromView.alpha = 0
//            toCellView.alpha = 1
//            toView.alpha = 1
//        }) { (completed) in
//            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
//        }
//    }
//}
