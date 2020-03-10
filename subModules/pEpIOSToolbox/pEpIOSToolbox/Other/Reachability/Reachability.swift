//
//  Reachability.swift
//  pEp
//
//  Created by Alejandro Gelos on 11/02/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.

import Foundation
import SystemConfiguration

public protocol ReachabilityDelegate: class {
    /// Called every time internet connection status changes. Also the first time startNotifier() is call
    ///
    /// - Parameter status: connected for connected to internet, otherwise notConnected
    func didChangeReachability(status: Reachability.Connection)
    func didFailToStartNotifier(error: Reachability.ReachabilityError)
}

///  This service allow an application to determine whether or not you have a working internet
///  connection.
///  Reachability supports asynchronous model. You get the internet connection status, in the
///  completion block by calling the getConnectionStatus(completion:failure:) function. You can also
///  call startNotifier() function, to start getting changes in internet connection status, on
///  ReachabilityDelegate, didChangeReachability(status:) function. The client must implement
///  ReachabilityDelegate to get new internet connection status. When startNotifier is call,
///  ReachabilityDelegate didChangeReachability(status:) will be call with the current internet
///  connection status.
///
/// # How to use:
///
/// # Start listening to new states
/// * instantiate Reachability class and retain it, ex: let <yourReachability> = Reachability()
/// * set ReachabilityDelegate to you (to get ReachabilityDelegate calls)
/// * implement ReachabilityDelegate (to get new connection states)
/// * call yourReachability.startNotifier() (start updating reachability status with delegate)
/// * call yourReachability.stopNotifier() (to stop updating)
///
/// # Get current state
/// * instantiate Reachability class
/// * call yourReachability.getConnectionStatus(
///    completion: { result in ...},
///    failure: { error in ...})
public final class Reachability: ReachabilityProtocol {
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
            callDelegateDidChangeReachabilityIfNeeded(newFlags: flags, oldFlags: oldValue)
        }
    }
    
    /// Get intense of Reachability, to check internet status
    public required init?() {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else { return nil }
        
        self.reachabilityRef = ref
        self.networkReachability = NetworkReachability()
        self.reachabilitySerialQueue =
            DispatchQueue(label: "pep.reachability", qos: .default, target: nil)
    }
    
    convenience init?(networkReachability: NetworkReachabilityProtocol) {
        self.init()
        self.networkReachability = networkReachability
    }
    
    deinit {
        stopNotifier()
    }
    
    /// Get current connection status
    ///
    /// - Parameters:
    ///   - completion: connected and not connected to internet
    ///   - failure: failToGetReachabilityState when failed to get internet status
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
    
    /// Start updating internet connection state through ReachabilityDelegate
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
    
    /// Stop updating reachable value
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
    
    private func callDelegateDidChangeReachabilityIfNeeded(newFlags: SCNetworkReachabilityFlags?,
                                                           oldFlags: SCNetworkReachabilityFlags?){
        guard let newFlags = newFlags else { return }
        let newState = getConnectionStatus(fromFlags: newFlags)
        
        guard let oldFlags = oldFlags else {
            delegate?.didChangeReachability(status: newState)
            return
        }
        
        let oldState = getConnectionStatus(fromFlags: oldFlags)
        if newState == oldState { return }
        delegate?.didChangeReachability(status: newState)
    }
}
