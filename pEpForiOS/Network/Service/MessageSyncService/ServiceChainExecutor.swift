//
//  ServiceChainExecutor.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

class ServiceChainExecutor {
    var services = [ServiceExecutionProtocol]()
    var currentlyExecutingService: ServiceExecutionProtocol?

    init(services: [ServiceExecutionProtocol]) {
        self.services = services
    }

    convenience init() {
        self.init(services: [])
    }

    func add(service: ServiceExecutionProtocol) {
        services.append(service)
    }

    func add(services: [ServiceExecutionProtocol]) {
        for s in services {
            add(service: s)
        }
    }
}

extension ServiceChainExecutor: ServiceExecutionProtocol {
    func cancel() {
        for service in services {
            service.cancel()
        }
    }

    func execute(handler: ServiceFinishedHandler? = nil) {
        if let service = services.first {
            let _ = services.remove(at: 0)
            Log.shared.info(component: #function, content: "executing \(service)")
            currentlyExecutingService = service
            service.execute() { [weak self] error in
                if let err = error {
                    let desc = String(describing: self?.currentlyExecutingService)
                    Log.shared.error(
                        component: #function,
                        errorString: "Error for \(desc): ",
                        error: err)
                    handler?(err)
                } else {
                    self?.execute(handler: handler)
                }
            }
        } else {
            currentlyExecutingService = nil
            handler?(nil)
        }
    }
}
