//
//  SmtpConnection.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PantomimeFramework
import pEpIOSToolbox

protocol SmtpConnectionDelegate: class {
    func messageSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func messageNotSent(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionInitiationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionInitiationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func recipientIdentificationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func recipientIdentificationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionResetCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func transactionResetFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func authenticationCompleted(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func authenticationFailed(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionEstablished(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionLost(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionTerminated(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func connectionTimedOut(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func requestCancelled(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func serviceInitialized(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func serviceReconnected(_ smtpConnection: SmtpConnectionProtocol, theNotification: Notification?)
    func badResponse(_ smtpConnection: SmtpConnectionProtocol, response: String?)
}

extension SmtpConnection {
    private struct Status {
        var haveStartedTLS = false
    }
}

class SmtpConnection: SmtpConnectionProtocol {
    private var smtp: CWSMTP

    private var smtpStatus: Status = Status()
    weak var delegate: SmtpConnectionDelegate?

    private let connectInfo: EmailConnectInfo

    /// The access token, if authMethod is .saslXoauth2
    private let accessToken: OAuth2AccessTokenProtocol?

    var isClientCertificateSet: Bool {
        return connectInfo.clientCertificate != nil
    }

    init(connectInfo: EmailConnectInfo) {
        self.connectInfo = connectInfo
        accessToken = connectInfo.accessToken()

        smtp = CWSMTP(name: connectInfo.networkAddress,
                      port: UInt32(connectInfo.networkPort),
                      transport: connectInfo.connectionTransport,
                      clientCertificate: connectInfo.clientCertificate)

        smtp.setDelegate(self)
    }

    func start() {
        smtp.connectInBackgroundAndNotify()
    }

    private func bestAuthMethodFromList(_ mechanisms: [String])  -> AuthMethod {
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

    private func bestAuthMethod()  -> AuthMethod {
        return bestAuthMethodFromList(smtp.supportedMechanisms() as? [String] ?? [])
    }
}

// MARK: - Wrap CWSMTP methods

extension SmtpConnection {
    func setRecipients(_ recipients: [Any]?) {
        smtp.setRecipients(recipients)
    }

    func setMessageData(_ data: Data?) {
        smtp.setMessageData(data)
    }

    func setMessage(_ message: CWMessage) {
        smtp.setMessage(message)
    }

    func sendMessage() {
        smtp.sendMessage()
    }
}

// MARK: - Wrap connect info data

extension SmtpConnection {
    var accountAddress: String {
        return connectInfo.account.address
    }
}

// MARK: - TransportClient

extension SmtpConnection: TransportClient {
    @objc func messageSent(_ theNotification: Notification?) {
        delegate?.messageSent(self, theNotification: theNotification)
    }

    @objc func messageNotSent(_ theNotification: Notification?) {
        delegate?.messageNotSent(self, theNotification: theNotification)
    }
}

// MARK: - SMTPClient

extension SmtpConnection: SMTPClient {
    @objc func transactionInitiationCompleted(_ theNotification: Notification?) {
        delegate?.transactionInitiationCompleted(self, theNotification: theNotification)
    }

    @objc func transactionInitiationFailed(_ theNotification: Notification?) {
        delegate?.transactionInitiationFailed(self, theNotification: theNotification)
    }

    @objc func recipientIdentificationCompleted(_ theNotification: Notification?) {
        delegate?.recipientIdentificationCompleted(self, theNotification: theNotification)
    }

    @objc func recipientIdentificationFailed(_ theNotification: Notification?) {
        delegate?.recipientIdentificationFailed(self, theNotification: theNotification)
    }

    @objc func transactionResetCompleted(_ theNotification: Notification?) {
        delegate?.transactionResetCompleted(self, theNotification: theNotification)
    }

    @objc func transactionResetFailed(_ theNotification: Notification?) {
        delegate?.transactionResetFailed(self, theNotification: theNotification)
    }
}

// MARK: - CWServiceClient

extension SmtpConnection: CWServiceClient {
    @objc func badResponse(_ theNotification: Notification?) {
        let errorMsg = theNotification?.parseErrorMessageBadResponse()
        delegate?.badResponse(self, response: errorMsg)
    }

    @objc func authenticationCompleted(_ theNotification: Notification?) {
        delegate?.authenticationCompleted(self, theNotification: theNotification)
    }

    @objc func authenticationFailed(_ theNotification: Notification?) {
        delegate?.authenticationFailed(self, theNotification: theNotification)
    }

    @objc func connectionEstablished(_ theNotification: Notification?) {
        delegate?.connectionEstablished(self, theNotification: theNotification)
    }

    @objc func connectionLost(_ theNotification: Notification?) {
        delegate?.connectionLost(self, theNotification: theNotification)
    }

    @objc func connectionTerminated(_ theNotification: Notification?) {
        delegate?.connectionTerminated(self, theNotification: theNotification)
    }

    @objc func connectionTimedOut(_ theNotification: Notification?) {
        delegate?.connectionTimedOut(self, theNotification: theNotification)
    }

    @objc func requestCancelled(_ theNotification: Notification?) {
        delegate?.requestCancelled(self, theNotification: theNotification)
    }

    @objc func serviceInitialized(_ theNotification: Notification?) {
        delegate?.serviceInitialized(self, theNotification: theNotification)
        if connectInfo.connectionTransport == ConnectionTransport.startTLS &&
            !smtpStatus.haveStartedTLS {
            smtpStatus.haveStartedTLS = true
            smtp.startTLS()
        } else {
            if connectInfo.authMethod == .saslXoauth2,
                let theLoginName = connectInfo.loginName,
                let token = accessToken {
                // The CWIMAPStore seems to expect that that its delegate (us) processes
                // synchronously and thus has all work done when returning.
                // I am not sure if the same is true for CWSMTP but took the waiting approach over
                // for safety reasons.
                let group = DispatchGroup()
                group.enter()
                token.performAction() { [weak self] error, freshToken in
                    if let err = error {
                        Log.shared.error(
                            "%@", "\(err)")
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
                                guard let token = freshToken else {
                                    group.leave()
                                    return
                                }
                                theSelf.smtp.authenticate(theLoginName,
                                                          password: token,
                                                          mechanism: theSelf.connectInfo.authMethod.rawValue)
                                group.leave()
                            }
                        } else {
                            Log.shared.lostMySelf()
                            group.leave()
                        }
                    }
                }
                group.wait()
            } else if let password = connectInfo.loginPassword,
                let theLoginName = connectInfo.loginName {
                smtp.authenticate(theLoginName,
                                  password: password,
                                  mechanism: bestAuthMethod().rawValue)
            } else {
                Log.shared.error("SMTP: Want to log in, but neither have a password nor a token")
                authenticationFailed(nil)
            }
        }
    }

    @objc public func serviceReconnected(_ theNotification: Notification?) {
        delegate?.serviceReconnected(self, theNotification: theNotification)
   }
}
