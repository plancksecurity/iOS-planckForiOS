//
//  ThreadNaviationDelegate
//  pEp
//
//  Created by Miguel Berrocal Gómez on 28/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

class ThreadNavigationDelegate: NSObject,
UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation:
        UINavigationControllerOperation,
        from fromVC: UIViewController,
        to toVC: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {

        if toVC is EmailViewController {
            return CellDetailTransition(duration: 0.5)
        }
        if fromVC is EmailViewController && operation == .pop {
            return CellDetailTransition(duration: 0.5, isDismissing: true)
        }
        return nil
    }
}
