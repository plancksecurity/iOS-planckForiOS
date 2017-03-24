//
//  IdentityImageProvider.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

typealias ImageReadyFunc = (UIImage) -> Void

class IdentityImageProvider {
    fileprivate var runningOperations = [Identity: (IdentityImageOperation, [ImageReadyFunc])]()
    fileprivate let dispatchQueue = DispatchQueue(label: "IdentityImageProvider Queue")
    fileprivate let backgroundQueue = OperationQueue()

    /**
     Request an image.
     */
    open func image(forIdentity identity: Identity, callback: @escaping ImageReadyFunc) {
        dispatchQueue.async {
            self.internalImage(forIdentity: identity, callback: callback)
        }
    }

    /**
     Cancel an image request.
     */
    open func cancel(identity: Identity) {
        dispatchQueue.async {
            self.internalCancel(identity: identity)
        }
    }

    fileprivate func internalImage(forIdentity identity: Identity,
                                   callback: @escaping ImageReadyFunc) {
        if let (op, funs) = runningOperations[identity] {
            var newFuns = funs
            newFuns.append(callback)
            runningOperations[identity] = (op, newFuns)
        } else {
            let op = IdentityImageOperation(identity: identity)
            op.completionBlock = { [weak self, weak identity] in
                self?.dispatchQueue.async {
                    if let theSelf = self, let theIdentity = identity {
                        theSelf.finished(identity: theIdentity)
                    }
                }
            }
            backgroundQueue.addOperation(op)
            runningOperations[identity] = (op, [callback])
        }
    }

    fileprivate func internalCancel(identity: Identity) {
        if let (op, _) = runningOperations.removeValue(forKey: identity) {
            op.cancel()
        }
    }

    fileprivate func finished(identity: Identity) {
        if let (op, funs) = runningOperations.removeValue(forKey: identity), let img = op.image {
            for f in funs {
                GCD.onMain {
                    f(img)
                }
            }
        }
    }
}
