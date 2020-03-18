//
//  ServiceProtocol.swift
//  MessageModel
//
//  Created by Andreas Buff on 12.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

/// Protocol every Service MUST conform to.
public protocol ServiceProtocol {

    /// Starts the service.
    func start()

    /// Tells the service to finish. There is no pressure to finish, but you should not take longer
    /// than required (do not repeat the repeat or such). Will be called e.g. when going into
    /// background. It is up to the service if and how to handle that.
    func finish()

    /// It's urgent! Stop as fast as possible. It is up to the service if and how to handle that.
    func stop()
}
