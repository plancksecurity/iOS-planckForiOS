//
//  FileExportUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 13/1/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation
import PlanckToolbox
import pEp4iosIntern
import PEPObjCAdapter

public protocol FileExportUtilProtocol: AnyObject {
    func exportDatabases() throws
    func save(auditEventLog: EventLog, maxLogTime: Int, errorCallback: @escaping (Error) -> Void)
}

public class FileExportUtil: NSObject, FileExportUtilProtocol {
    
    // MARK: - Singleton
    
    static public let shared = FileExportUtil()

    private override init() { }

    private let planckFolderName = "planck"
    private let auditLogginggFileName = "auditLoggingg"
    private let csvExtension = "csv"
    private let commaSeparator = ","
    private let newLine = "\n"
    private var auditLoggingFilePath: URL?
    private let beginPGP = "-----BEGIN PGP MESSAGE----"
    private let endPGP = "-----END PGP MESSAGE-----\n"

    private let auditLogQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = "security.planck.auditLoggging.fileExportUtil.queueForSavingLogs"
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    private let auditLogSignQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = "security.planck.auditLoggging.fileExportUtil.signQueueForSavingLogs"
        createe.qualityOfService = .userInteractive
        createe.maxConcurrentOperationCount = 1
        return createe
    }()

    /// Export databases
    ///
    /// - Throws: throws an error in cases of failure.
    public func exportDatabases() throws {
        let systemDBFileName = "system.db"
        let pepFolderName = "pEp"
        
        do {
            let fileManager = FileManager.default
            guard let destinationDirectoryURL: URL = getDBDestinationDirectoryURL() else {
                Log.shared.errorAndCrash("Destination Directory URL not found")
                return
            }
            
            //Check if destination directory already exists. If not, create it.
            var isDirectory:ObjCBool = true
            if !fileManager.fileExists(atPath: destinationDirectoryURL.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
            }
            
            //Get the destination path of each file and copy items from source paths to the destination paths
            let pepFolderDestinationPath = getDestinationPath(from: destinationDirectoryURL, fileName: pepFolderName)
            let systemDBDestinationPath = getDestinationPath(from: destinationDirectoryURL, fileName: systemDBFileName)
            
            //System DB
            if let systemDBsourcePath = getSystemDBSourceURL()?.path {
                var isDirectory:ObjCBool = false
                if fileManager.fileExists(atPath: systemDBDestinationPath, isDirectory: &isDirectory) {
                    try fileManager.removeItem(atPath: systemDBDestinationPath)
                }
                try fileManager.copyItem(atPath: systemDBsourcePath, toPath: systemDBDestinationPath)
            }
            //.pEp folder
            if let pepHiddenFolderSourcePath = getSourceURLforHiddenPEPFolder()?.path {
                try fileManager.copyItem(atPath: pepHiddenFolderSourcePath, toPath: pepFolderDestinationPath)
            }
            
            //security.pEp DB files
            if let path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier)?.path,
               let items = try? fileManager.contentsOfDirectory(atPath: path) {
                let filesNames = items.filter { $0.contains("security.pEp") }
                try? filesNames.forEach { fileName in
                    let securityPEPsqliteDestinationPath = getDestinationPath(from: destinationDirectoryURL, fileName: fileName)
                    if let pepSecuritySQLiteDBsourcePath = getSQLiteDBSourceURL(fileName: fileName)?.path {
                        try fileManager.copyItem(atPath: pepSecuritySQLiteDBsourcePath, toPath: securityPEPsqliteDestinationPath)
                    }
                }
            }
        }
    }
}

// MARK: - Audit Loggin

extension FileExportUtil {
    
    enum SignError: Error {
        case signatureNotVerified
        case emptyString
        case filepathNotFound
    }
    
    private func getCSVContent() -> String? {
        guard let filePath = auditLoggingFilePath else {
            Log.shared.errorAndCrash("File path not found")
            return nil
        }
        do {
            // Get the content of the file as data.
            let data = try Data(contentsOf: filePath)
            
            // Convert to string, so it's readable and parseable.
            return String(decoding: data, as: UTF8.self)
        } catch {
            Log.shared.errorAndCrash(error: error)
            return nil
        }
    }
    
    public func save(auditEventLog: EventLog, maxLogTime: Int, errorCallback: @escaping (Error) -> Void) {
        auditLogQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            // 1. Craft the CVS.
            // - if it already exists, add a row.
            // - Otherwise, create it with the given row.
            guard let newCsv = me.createCSV(auditEventLog: auditEventLog, maxLogTime: maxLogTime) else {
                Log.shared.error("CSV not saved. Probably filepath not found")
                errorCallback(SignError.filepathNotFound)
                return
            }
            
            let group = DispatchGroup()

            // 3. If the file already exists, it already has a signature: Validate it.
            // If signature is valid, the file is persisted.
            // Otherwise, the user is notified.
            if let previousCsvContent = me.getCSVContent() {
                // Verify the signature
                var resultantCSV = newCsv
                let signature = me.extractSignatureFrom(csv: resultantCSV)
                var previousCsvWithoutSignature = me.removeSignatureFrom(csv: previousCsvContent, signature: signature)
                group.enter()
                PEPSession().verifyText(previousCsvWithoutSignature, signature: signature) { error in
                    // Verification failed, inform the user.
                    defer { group.leave() }
                    errorCallback(error)
                } successCallback: { success in
                    guard success else {
                        Log.shared.errorAndCrash("The signature was not verified")
                        errorCallback(SignError.signatureNotVerified)
                        return
                    }
                    
                    // The signature is valid.
                    let rows = previousCsvWithoutSignature.components(separatedBy: me.newLine).filter { !$0.isEmpty }
                    var logs = [EventLog]()
                    rows.forEach { row in
                        let values = row.components(separatedBy: me.commaSeparator)
                        let eventLog = EventLog(values)
                        logs.append(eventLog)
                    }
                    resultantCSV = me.getAllEntries(auditEventLog: auditEventLog, logs: logs)

                    guard !newCsv.isEmpty else {
                        Log.shared.errorAndCrash("Invalid argument: an empty string can't be signed")
                        errorCallback(SignError.emptyString)
                        return
                    }
                    group.enter()
                    PEPSession().signText(newCsv) { error in
                        defer { group.leave() }
                        errorCallback(error)
                    } successCallback: { signature in
                        me.appendSignatureAndSave(csv: newCsv, signature: signature)
                        group.leave()
                    }
                    group.wait()
                }
            } else {
                // Sign and Save
                guard !newCsv.isEmpty else {
                    Log.shared.errorAndCrash("Invalid argument: an empty string can't be signed")
                    errorCallback(SignError.emptyString)
                    return
                }
                group.enter()
                PEPSession().signText(newCsv) { error in
                    defer { group.leave() }
                    errorCallback(error)
                } successCallback: { signature in
                    me.appendSignatureAndSave(csv: newCsv, signature: signature)
                    group.leave()
                }
                group.wait()

            }
        }
    }
}

// MARK: - Private - Audit Loggin

extension FileExportUtil {
    
    private func csvFileAlreadyExists() -> Bool {
        do {
            let fileManager = FileManager.default
            guard let auditLoggingDestinationDirectoryURL = getAuditLoggingDestinationDirectoryURL() else {
                Log.shared.errorAndCrash("Audit logging Destination Directory URL not found")
                return false
            }
            
            // Check if destination directory already exists. If not, create it.
            var isDirectory: ObjCBool = true
            if !fileManager.fileExists(atPath: auditLoggingDestinationDirectoryURL.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: auditLoggingDestinationDirectoryURL, withIntermediateDirectories: true)
            }
            
            var url = auditLoggingDestinationDirectoryURL.appendingPathComponent(auditLogginggFileName)
            url = url.appendingPathExtension(csvExtension)
            // Keep the file url
            auditLoggingFilePath = url
            
            // Check if the file already exists.
            if #available(iOS 16.0, *) {
                return fileManager.fileExists(atPath: url.path())
            } else {
                return fileManager.fileExists(atPath: url.path)
            }
        } catch {
            Log.shared.errorAndCrash(error: error)
            return false
        }
    }

    private func createCSV(auditEventLog: EventLog, maxLogTime: Int) -> String? {
        var logs = [EventLog]()
        do {
            guard let content = getCSVContent() else {
                return auditEventLog.entry
            }
            var signature = beginPGP
            var components: [String] = content.components(separatedBy: beginPGP)
            if let signatureSuffix = components.last {
                signature.append(signatureSuffix) // Complete Signature
                components.removeLast() // Components of CSV, without the signature.
            }
            
            // Get rows of the content
            let rows = components.joined().components(separatedBy: newLine).filter { !$0.isEmpty }
            
            // Convert strings to EventLog (objects)
            rows.forEach { row in
                let values = row.components(separatedBy: commaSeparator)
                let eventLog = EventLog(values)
                
                // Get the date and evaluate if the entry should be included into the CSV file.
                if let timestamp = values.first, let timeResult = Double(timestamp) {
                    let date = Date(timeIntervalSince1970: timeResult)
                    if let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day,
                       days <= maxLogTime {
                        logs.append(eventLog)
                    }
                }
            }
            
            var resultantEntries = signature
            let newEntries = getAllEntries(auditEventLog: auditEventLog, logs: logs)
            resultantEntries.append(newEntries)
            return resultantEntries
        }
    }
    
    // All entries mean: previous entries + current entry.
    private func getAllEntries(auditEventLog: EventLog, logs: [EventLog]) -> String {
        // All entries mean: previous entries + current entry.
        let previousEntries: [String] = logs.compactMap { $0.entry.trimmed() }
        var allEntries = previousEntries
        allEntries.append(auditEventLog.entry)
        return allEntries.joined(separator: newLine)
    }
    
    /// - Returns: The destination directory url.
    private func getAuditLoggingDestinationDirectoryURL() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docUrl = documentsUrl else {
            Log.shared.errorAndCrash("Documents not found")
            return nil
        }
        return docUrl
    }

    private func signAndSave(csv: String, errorCallback: @escaping (Error) -> Void) {
        auditLogSignQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.error(error: "Lost Myself")
                return
            }
            guard !csv.isEmpty else {
                Log.shared.errorAndCrash("Invalid argument: an empty string can't be signed")
                errorCallback(SignError.emptyString)
                return
            }
            let group = DispatchGroup()
            group.enter()
            PEPSession().signText(csv) { error in
                defer { group.leave() }
                errorCallback(error)
            } successCallback: { signature in
                me.appendSignatureAndSave(csv: csv, signature: signature)
                group.leave()
            }
            group.wait()
        }
    }

    private func appendSignatureAndSave(csv: String, signature: String) {
        // Append the signature at the begining of the file.
        var signedCSV = signature
        signedCSV.append(csv)
        
        // Save the file in disk.
        saveInDisk(csv: signedCSV)
    }
    
    private func saveInDisk(csv: String) {
        do {
            guard let data = csv.data(using: .utf8),
                  let fileUrl = auditLoggingFilePath else {
                Log.shared.errorAndCrash("Can't save CSV file")
                return
            }
            try data.write(to: fileUrl)
            Log.shared.info("CSV file successfully saved")
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }
    
    // MARK: - Signature

    private func extractSignatureFrom(csv: String) -> String {
        guard let result = csv.slice(from: beginPGP, to: endPGP) else {
            Log.shared.errorAndCrash("CSV does not contain signature")
            return ""
        }
        return beginPGP + result + endPGP
    }

    private func removeSignatureFrom(csv: String, signature: String) -> String {
        return csv.removeFirstOccurrence(of: signature)
    }
}

//MARK: - Private

extension FileExportUtil {
    
    /// Get the path of the file passed by param.
    /// - Parameters:
    ///   - url: The url of the file
    ///   - fileName: The name of the file
    private func getDestinationPath(from url: URL, fileName: String) -> String {
        var copyFileName = fileName
        if fileName.starts(with: ".") {
            copyFileName.removeFirst()
        }
        var urlCopy = URL(string: url.absoluteString)
        urlCopy?.appendPathComponent(copyFileName)
        guard let path = urlCopy?.path else {
            Log.shared.errorAndCrash("Destination Directory URL not found")
            return ""
        }
        return path
    }
    
    /// - Returns: The destination directory url.
    /// The last path component indicates the date and time.
    /// It could be something like '.../Documents/db-export/{YYYYMMDD-hh-mm}/'
    private func getDBDestinationDirectoryURL() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard var docUrl = documentsUrl else {
            Log.shared.errorAndCrash("Documents not found")
            return nil
        }
        docUrl.appendPathComponent("db-export")
        docUrl.appendPathComponent("\(getDatetimeAsString())")
        return docUrl
    }
    
    /// - Returns: The source url for the hidden p≡p folder
    private func getSourceURLforHiddenPEPFolder() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("pEp_home/.pEp/")
        return appGroupURL
    }
    
    /// - Returns: the URL where the system.db file is stored
    private func getSystemDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("pEp_home")
        appGroupURL.appendPathComponent("system.db")
        return appGroupURL
    }
    
    /// - Returns: the URL where the security.pEp files are stored
    private func getSQLiteDBSourceURL(fileName: String) -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent(fileName)
        return appGroupURL
    }
    
    /// - Returns: the date as string using the date format YYYYMMDD-hh-mm-ss.
    private func getDatetimeAsString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMDD-hh-mm-ss"
        return dateFormatter.string(from: date)
    }
}
