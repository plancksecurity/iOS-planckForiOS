//
//  SmtpSend.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

public protocol SmtpSendDelegate: class {
    func messageSent(_ smtp: SmtpSend, theNotification: Notification?)
    func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?)
    func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionLost(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?)
    func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?)
    func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?)
    func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?)
    func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?)
    func badResponse(_ smtp: SmtpSend, response: String?)
}

open class SmtpSendDefaultDelegate: SmtpSendDelegate {
    open func badResponse(_ smtp: SmtpSend, response: String?) {}
    open func messageSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func messageNotSent(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionInitiationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionInitiationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func recipientIdentificationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func recipientIdentificationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionResetCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func transactionResetFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func authenticationCompleted(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func authenticationFailed(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionEstablished(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionLost(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionTerminated(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func connectionTimedOut(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func requestCancelled(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func serviceInitialized(_ smtp: SmtpSend, theNotification: Notification?) {}
    open func serviceReconnected(_ smtp: SmtpSend, theNotification: Notification?) {}

    public init() {}
}

struct SmtpStatus {
    var haveStartedTLS = false
}

open class SmtpSend: Service {
    open override var comp: String { get { return "SmtpSend" } }

    private var smtpStatus: SmtpStatus = SmtpStatus.init()
    weak open var delegate: SmtpSendDelegate?

    var smtp: CWSMTP {
        get {
            return service as! CWSMTP
        }
    }

    open override func createService() -> CWService {
        return CWSMTP.init(name: connectInfo.networkAddress,
                           port: UInt32(connectInfo.networkPort),
                           transport: connectInfo.connectionTransport!)
    }

    open override func bestAuthMethodFromList(_ mechanisms: [String])  -> AuthMethod {
        if mechanisms.count > 0 {
            let mechanismsLC = mechanisms.map() { mech in
                return mech.lowercased()
            }

            let s = Set(mechanismsLC)

            if s.contains("cram-md5") {
                return .cramMD5
            } else if s.contains("plain") {
                return .plain
            } else if s.contains("login") {
                return .login
            }

            return .login
        } else {
            // no auth mechanisms have been provided by the server
            return .login
        }
    }
}

extension SmtpSend: TransportClient {
    @objc public func messageSent(_ theNotification: Notification?) {
        dumpMethodName("messageSent", notification: theNotification)
        delegate?.messageSent(self, theNotification: theNotification)
    }

    @objc public func messageNotSent(_ theNotification: Notification?) {
        dumpMethodName("messageNotSent", notification: theNotification)
        delegate?.messageNotSent(self, theNotification: theNotification)
    }
}

extension SmtpSend: SMTPClient {
    @objc public func transactionInitiationCompleted(_ theNotification: Notification?) {
        dumpMethodName("transactionInitiationCompleted", notification: theNotification)
        delegate?.transactionInitiationCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionInitiationFailed(_ theNotification: Notification?) {
        dumpMethodName("transactionInitiationFailed", notification: theNotification)
        delegate?.transactionInitiationFailed(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationCompleted(_ theNotification: Notification?) {
        dumpMethodName("recipientIdentificationCompleted", notification: theNotification)
        delegate?.recipientIdentificationCompleted(self, theNotification: theNotification)
    }

    @objc public func recipientIdentificationFailed(_ theNotification: Notification?) {
        dumpMethodName("recipientIdentificationFailed", notification: theNotification)
        delegate?.recipientIdentificationFailed(self, theNotification: theNotification)
    }

    @objc public func transactionResetCompleted(_ theNotification: Notification?) {
        dumpMethodName("transactionResetCompleted", notification: theNotification)
        delegate?.transactionResetCompleted(self, theNotification: theNotification)
    }

    @objc public func transactionResetFailed(_ theNotification: Notification?) {
        dumpMethodName("transactionResetFailed", notification: theNotification)
        delegate?.transactionResetFailed(self, theNotification: theNotification)
    }
}

extension SmtpSend: CWServiceClient {
    @objc public func badResponse(_ theNotification: Notification?) {
        dumpMethodName(#function, notification: theNotification)
        let errorMsg = theNotification?.parseErrorMessageBadResponse()
        delegate?.badResponse(self, response: errorMsg)
    }

    @objc public func authenticationCompleted(_ theNotification: Notification?) {
        dumpMethodName("authenticationCompleted", notification: theNotification)
        delegate?.authenticationCompleted(self, theNotification: theNotification)
    }

    @objc public func authenticationFailed(_ theNotification: Notification?) {
        dumpMethodName("authenticationFailed", notification: theNotification)
        delegate?.authenticationFailed(self, theNotification: theNotification)
    }

    @objc public func connectionEstablished(_ theNotification: Notification?) {
        dumpMethodName("connectionEstablished", notification: theNotification)
        delegate?.connectionEstablished(self, theNotification: theNotification)
    }

    @objc public func connectionLost(_ theNotification: Notification?) {
        dumpMethodName("connectionLost", notification: theNotification)
        delegate?.connectionLost(self, theNotification: theNotification)
    }

    @objc public func connectionTerminated(_ theNotification: Notification?) {
        dumpMethodName("connectionTerminated", notification: theNotification)
        delegate?.connectionTerminated(self, theNotification: theNotification)
    }

    @objc public func connectionTimedOut(_ theNotification: Notification?) {
        dumpMethodName("connectionTimedOut", notification: theNotification)
        delegate?.connectionTimedOut(self, theNotification: theNotification)
    }

    @objc public func requestCancelled(_ theNotification: Notification?) {
        dumpMethodName("requestCancelled", notification: theNotification)
        delegate?.requestCancelled(self, theNotification: theNotification)
    }

    @objc public func serviceInitialized(_ theNotification: Notification?) {
        dumpMethodName("serviceInitialized", notification: theNotification)
        delegate?.serviceInitialized(self, theNotification: theNotification)
        if self.connectInfo.connectionTransport == ConnectionTransport.startTLS &&
            !self.smtpStatus.haveStartedTLS {
            self.smtpStatus.haveStartedTLS = true
            self.smtp.startTLS()
        } else {
            if let authMethod = connectInfo.authMethod,
                authMethod == .saslXoauth2,
                let loginName = connectInfo.loginName,
                let token = connectInfo.accessToken {
                // The CWIMAPStore seems to expect that that its delegate (us) processes
                // synchronously and thus has all work done when returning.
                // I am not sure if the same is true for CWSMTP but took the waiting approach over
                // for safety reasons.
                let group = DispatchGroup()
                group.enter()
                token.performAction() { [weak self] error, freshToken in
                    if let err = error {
                        Log.shared.error(component: #function, error: err)
                        if let theSelf = self {
                            theSelf.delegate?.authenticationFailed(theSelf, theNotification: nil)
                        }
                        group.leave()
                    } else {
                        if let theSelf = self {
                            // Our OAuthToken runs this competion handler on the main thread,
                            // thus we dispatch away from it.
                            let queue = DispatchQueue(label: "net.pep-security.pep4iOS.NetworkService.ImapService")
                            queue.sync {
                                theSelf.smtp.authenticate(
                                    loginName, password: freshToken, mechanism: authMethod.rawValue)
                                group.leave()
                            }
                        } else {
                            Log.shared.errorAndCrash(component: #function,
                                                     errorString: "Lost myself")
                            group.leave()

                        }
                    }

                }
                group.wait()
            } else if let loginName = connectInfo.loginName,
                let password = connectInfo.loginPassword {
                self.smtp.authenticate(loginName, password: password,
                                       mechanism: self.bestAuthMethod().rawValue)
            } else {
                var missingToken = ""
                if connectInfo.loginName == nil {
                    missingToken = "loginName"
                } else {
                    missingToken = "loginPassword"
                }
                Log.warn(
                    component: #function,
                    content: "Don't have \(missingToken) for \(connectInfo.networkAddress) (\(String(describing: connectInfo.emailProtocol)))")
                authenticationFailed(nil)
            }
        }
    }

    @objc public func serviceReconnected(_ theNotification: Notification?) {
        dumpMethodName("serviceReconnected", notification: theNotification)
        delegate?.serviceReconnected(self, theNotification: theNotification)
   }
}
