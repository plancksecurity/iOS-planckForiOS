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
    func didFailToStartNotifier(error: Reachability.ReachabilityError)
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
            callDelegateDidChangeReachibilityIfNeeded(newFlags: flags, oldFlags: oldValue)
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
    
    public func getConnectionStatus(completion: @escaping ((Connection)->()),
                                       failure: @escaping ((ReachabilityError) -> ()) ) {
        setReachabilityFlags(
            completion: { [weak self] flags in
                guard let `self` = self else { return }
                let connectionStatud = self.getConnectionStatus(fromFlags: flags)
                completion(connectionStatud)},
            failure: { error in
                failure(error)
        })
    }
    
    public func isLocal(completion: @escaping ((Bool)->()),
                           failure: @escaping ((ReachabilityError) -> ()) ) {
        setReachabilityFlags(
            completion: { [weak self] flags in
                guard let `self` = self else { return }
                let isLocal = self.isLocal(fromFlags: flags)
                completion(isLocal)},
            failure: { error in
              failure(error)
        })
    }
    
    public func startNotifier() {
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
            delegate?.didFailToStartNotifier(error: .failToGetReachabilityState)
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            delegate?.didFailToStartNotifier(error: .failToGetReachabilityState)
        }
        
        // Perform an initial check
        setReachabilityFlags(
            completion: { [weak self] flags in
                self?.flags = flags },
            failure: { [weak self] error in
                self?.stopNotifier()
                self?.delegate?.didFailToStartNotifier(error: error)
        })
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
    private func setReachabilityFlags(completion: @escaping ((SCNetworkReachabilityFlags)->()),
                                         failure: @escaping ((ReachabilityError) -> ()) ) {
        reachabilitySerialQueue.async { [weak self] in
            guard let `self` = self else { return }
            var flags = SCNetworkReachabilityFlags()
            guard self.networkReachability.networkReachabilityGetFlags(self.reachabilityRef, &flags) else {
                failure(.failToGetReachabilityState)
                return
            }
             completion(flags)
        }
    }
    
    private func getConnectionStatus(fromFlags: SCNetworkReachabilityFlags) -> Connection {
        return fromFlags.contains(.reachable) ? .connected : .notConnected
    }
    
    private func isLocal(fromFlags: SCNetworkReachabilityFlags) -> Bool {
        return fromFlags.contains(.isLocalAddress)
    }
    
    private func callDelegateDidChangeReachibilityIfNeeded(newFlags: SCNetworkReachabilityFlags?,
                                                           oldFlags: SCNetworkReachabilityFlags?){
        guard let newFlags = newFlags else { return }
        let newState = getConnectionStatus(fromFlags: newFlags)
        
        guard let oldFlags = oldFlags else {
            delegate?.didChangeReachibility(status: newState)
            return
        }
        
        let oldState = getConnectionStatus(fromFlags: oldFlags)
        if newState == oldState { return }
        delegate?.didChangeReachibility(status: newState)
    }
}
