//
//  BackgroundTaskManager.swift
//  MessageModel
//
//  Created by Andreas Buff on 01.09.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import UIKit
import pEpIOSToolbox

/// Manages UIBackgroundTasks & UIBackgroundTaskIdentifier
/// You MUST use this if you are running an OP that is potentionally still running after the app transitioned to background.
/// You MUST NOT use any other funtionality to get an UIBackgroundTaskIdentifier
protocol BackgroundTaskManagerProtocol {

    /// Creates and manages a UIBackgroundTaskIdentifier for the client.
    ///
    /// The client (you!) is responsible for reporting start and end of a background task.
    /// The BackgroundTaskManager is responsible to communicating this to the OS.
    ///
    /// - note: You MUST use this if you are running an OP that is potentionally still running
    ///         after the app transitioned to background.
    ///         You MUST NOT use any other funtionality to get an UIBackgroundTaskIdentifier.
    ///         One client can run 1 task max.
    ///
    /// - Parameter client: the class asking for communicating it's (potiential) background
    ///                     activity to the OS.
    /// - Parameter handler:    A handler to be called shortly before the app’s time reaches 0.
    ///                         See ExiredHandler docs for details.
    ///
    /// - Throws: ManagingError.backgroundTaskAlreadyRunning
    func startBackgroundTask(for client: AnyHashable,
                             expirationHandler handler: (()->Void)?) throws

    /// Stops the background task of the client and invalidates the UIBackgroundTaskIdentifier.
    /// Calling this method without having a background task registered is considered as an error
    /// and throws.
    ///
    /// The client (you!) is responsible for reporting start and end of a background task.
    /// The BackgroundTaskManager is responsible to communicating this to the OS.
    ///
    /// - Parameter client: the class asking for communicating it's (potiential) background
    ///             activity to the OS.
    /// - Throws:   ManagingError.unknownClient,
    ///             ManagingError.startingBackgroundTaskIsCurrentlyImpossible
    func endBackgroundTask(for client: AnyHashable) throws
}

// MARK: - ManagingError

extension BackgroundTaskManager {

    enum ManagingError: Error, Equatable {

        /// The OS denied to start a background task
        case startingBackgroundTaskIsCurrentlyImpossible

        /// A client wants to start a background task, but the number of running tasks for this
        /// client is > 0.
        case backgroundTaskAlreadyRunning

        /// An unknown client asks for ending a backgound task.
        case unknownClient
    }
}

/// - note: It is thread save.
class BackgroundTaskManager {
    /// Bookholding: task IDs for clients.
    private var runningTasks = [AnyHashable:UIBackgroundTaskIdentifier]()
}

// MARK: - BackgroundTaskManagerProtocol

extension BackgroundTaskManager: BackgroundTaskManagerProtocol {

    /// For docs see BackgroundTaskManagerProtocol
    func startBackgroundTask(for client: AnyHashable,
                             expirationHandler handler: (()->Void)? = nil) throws {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard runningTasks[client] == nil else {
            throw BackgroundTaskManager.ManagingError.backgroundTaskAlreadyRunning
        }

        let createe = UIApplication.shared.beginBackgroundTask(withName: "\(client)") { [weak self]  in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            // Call the clients cleanup handler ...
            handler?()

            // ... and cleanup our self

            // Using `?` is OK here. We are called by the OS to let us know that we are over time and
            // gonna get killed very soon. We do what we can to gracfully end before this
            // happens, but throwing would help nobody here.
            try? me.endBackgroundTask(for: client)
        }

        if createe == .invalid {
            throw BackgroundTaskManager.ManagingError.startingBackgroundTaskIsCurrentlyImpossible
        }
        runningTasks[client] = createe
        Log.shared.info("Did start backgroundtask with id: %@ for service: %@",
                        "\(createe)", client.debugDescription)
    }

    /// For docs see BackgroundTaskManagerProtocol
    func endBackgroundTask(for client: AnyHashable) throws {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }

        guard var endedTaskID = runningTasks.removeValue(forKey: client) else {
            // We are not aware of a running task for this client. Throw!
            throw BackgroundTaskManager.ManagingError.unknownClient
        }
        UIApplication.shared.endBackgroundTask(endedTaskID)
        Log.shared.info("Did end backgroundtask with id: %@ for service: %@",
        "\(endedTaskID)", client.debugDescription)
        endedTaskID = UIBackgroundTaskIdentifier.invalid
    }
}
