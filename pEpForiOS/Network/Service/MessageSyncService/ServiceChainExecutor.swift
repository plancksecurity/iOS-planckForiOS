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
    func execute(handler: ServiceFinishedHandler? = nil) {
        execute(services: services, handler: handler)
    }

    func execute(services: [ServiceExecutionProtocol], handler: ServiceFinishedHandler?) {
        if let service = services.first {
            let restOfServices = services.dropFirst()
            Log.shared.info(component: #function, content: "executing \(service)")
            service.execute() { [weak self] error in
                if let err = error {
                    Log.shared.error(
                        component: #function,
                        errorString: "Error for \(service): ",
                        error: err)
                    handler?(err)
                } else {
                    self?.execute(services: Array(restOfServices), handler: handler)
                }
            }
        } else {
            handler?(nil)
        }
    }
}
