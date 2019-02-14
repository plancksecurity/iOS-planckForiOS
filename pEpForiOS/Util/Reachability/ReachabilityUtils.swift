//
//  ReachabilityUtils.swift
//  pEp
//
//  Created by Alejandro Gelos on 11/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import SystemConfiguration

public protocol ReachabilityDelegate: class {
    /// Called every time internet connection changes state
    ///
    /// - Parameter status: new internet connection state
    func didChangeReachibility(status: Reachability.Connection)
}

/// # How to use:
///
/// # Start listening to new states
/// * instantiate Reachability class and retain it
/// * set ReachabilityDelegate to you  (to get ReachabilityDelegate calls)
/// * implement ReachabilityDelegate   (to get new connection states)
/// * call yourRchabilityInstance.startNotifier() (start updating status with delegate, also called with the current status)
/// * call yourRchabilityInstance.stopNotifier() (to stop updating the connection status)
///
/// # Get current state
/// * instantiate Reachability class
/// * call yourRchabilityInstance.getConnectionStatus()
public final class Reachability: ReachibilityUtilsProtocol {
    public enum Connection: String {
        case notConnected, connected
    }
    
    /// ReachabilityError types
    ///
    /// - failToGetReachabilityState: failt to get reachability state
    public enum ReachabilityError: Error {
        case failToGetReachabilityState
    }

    public weak var delegate: ReachabilityDelegate?
    
    private var notifierRunning = false
    private var networkReachability: NetworkReachabilityProtocol
    private let reachabilityRef: SCNetworkReachability
    private let reachabilitySerialQueue: DispatchQueue
    
    var flags: SCNetworkReachabilityFlags? {
        didSet {
            let newState = getConnectionStatusFromFlags(fromFlags: flags)
            let oldState = getConnectionStatusFromFlags(fromFlags: oldValue)
            if newState != oldState, oldValue != nil { return }
            delegate?.didChangeReachibility(status: newState)
        }
    }
    
    required public init(reachabilityRef: SCNetworkReachability, queueQoS: DispatchQoS = .default,
                         targetQueue: DispatchQueue? = nil) {
        self.reachabilityRef = reachabilityRef
        self.networkReachability = NetworkReachability()
        self.reachabilitySerialQueue =
            DispatchQueue(label: "pep.reachability", qos: queueQoS, target: targetQueue)
    }
    
    public convenience init?(hostname: String, queueQoS: DispatchQoS = .default,
                               targetQueue: DispatchQueue? = nil) {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else { return nil }
        
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue)
    }
    
    public convenience init?(queueQoS: DispatchQoS = .default, targetQueue: DispatchQueue? = nil) {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else { return nil }
        
        self.init(reachabilityRef: ref,queueQoS: queueQoS, targetQueue: targetQueue)
    }
    
    convenience init?(networkReachability: NetworkReachabilityProtocol) {
        self.init()
        self.networkReachability = networkReachability
    }
    
    deinit {
        stopNotifier()
    }
    
    public func getConnectionStatus() throws -> Connection {
        try setReachabilityFlags()
        return getConnectionStatusFromFlags(fromFlags: flags)
    }
    
    public func startNotifier() throws {
        guard !notifierRunning else { return }
        
        let callback: SCNetworkReachabilityCallBack = { (reachability, flags, info) in
            guard let info = info else { return }
            
            let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
            reachability.flags = flags
        }
        
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil,
                                                   copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
        if !networkReachability.networkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.failToGetReachabilityState
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.failToGetReachabilityState
        }
        
        // Perform an initial check
        try setReachabilityFlags()
        
        notifierRunning = true
    }
    
    public func stopNotifier() {
        defer { notifierRunning = false }
        
        networkReachability.networkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
}


// MARK: - Private methods
private extension Reachability {
    private func setReachabilityFlags() throws {
        try reachabilitySerialQueue.sync { [weak self] in
            guard let `self` = self else { return }
            var flags = SCNetworkReachabilityFlags()
            guard networkReachability.networkReachabilityGetFlags(self.reachabilityRef, &flags) else {
                self.stopNotifier()
                throw ReachabilityError.failToGetReachabilityState
            }
            
            self.flags = flags
        }
    }
    
    private func getConnectionStatusFromFlags(fromFlags flags: SCNetworkReachabilityFlags?) -> Connection {
        guard let flags = flags else { return .notConnected }
        return flags.contains(.reachable) ? .connected : .notConnected
    }
}
