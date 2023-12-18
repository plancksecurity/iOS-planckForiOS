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
    func save(auditEventLog: EventLog, maxNumberOfDays: Int, errorCallback: @escaping (Error) -> Void)
}

public class FileExportUtil: NSObject, FileExportUtilProtocol {
    
    // MARK: - Singleton
    
    static public let shared = FileExportUtil()

    private override init() { }

    private let auditLoggingFileName = "auditLogging"
    private let csvExtension = "csv"
    private let commaSeparator = ","
    private let newLine = "\n"
    private var auditLoggingFilePath: URL?

    private let auditLogQueue: OperationQueue = {
        let createe = OperationQueue()
        createe.name = "security.planck.auditLogging.fileExportUtil.queueForSavingLogs"
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

// MARK: - Async/Await wrappers

extension FileExportUtil {
    private func verifyText(text: String, signature: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            PEPSession().verifyText(text, signature: signature, errorCallback: { error in
                continuation.resume(throwing: error)
            }, successCallback: { success in
                continuation.resume(returning: success)
            })
        }
    }

    private func signText(text: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            PEPSession().signText(text, errorCallback: { error in
                continuation.resume(throwing: error)
            }, successCallback: { success in
                continuation.resume(returning: success)
            })
        }
    }
}

// MARK: - Audit Logging

extension FileExportUtil {
    
    enum SignError: Error {
        case signatureNotVerified
        case emptyString
        case filepathNotFound
    }

    public func save(auditEventLog: EventLog,
                     maxNumberOfDays: Int,
                     errorCallback: @escaping (Error) -> Void) {
        auditLogQueue.addOperation { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let persistedCsvContent = me.getPersistedCSVContent() else {
                me.createFirstCSV(auditEventLog: auditEventLog, errorCallback: errorCallback)
                return
            }
            var newCsv = me.createCSV(auditEventLog: auditEventLog, maxNumberOfDays: maxNumberOfDays, persistedCSVContent: persistedCsvContent)
            let signature = me.extractSignatureFrom(csv: persistedCsvContent)
            let csv = me.removeSignatureFrom(csv: persistedCsvContent, signature: signature)
            me.save(csv: csv, signature: signature, auditEventLog: auditEventLog, errorCallback: errorCallback)
        }
    }
    
    private func save(csv: String, signature: String, auditEventLog: EventLog, errorCallback: @escaping (Error) -> Void) {
        Task {
            let result = try await verifyText(text: csv, signature: signature)
            guard result else {
                errorCallback(SignError.signatureNotVerified)
                return
            }
            let persistedLogs = getLogs(csv: csv)
            let resultantCSV = getAllEntries(auditEventLog: auditEventLog, logs: persistedLogs)
            let signature = try await signText(text: resultantCSV)
            prependSignatureAndSave(csv: resultantCSV, signature: signature, errorCallback: errorCallback)
        }
    }
}

// MARK: - Private - Audit Loggin

extension FileExportUtil {
    
    private func csvFileAlreadyExists() -> Bool {
        setPathIfNeeded()
        guard let url = auditLoggingFilePath else {
            Log.shared.errorAndCrash("No Path. Should not happened.")
            return false
        }

        // Check if the file already exists.
        if #available(iOS 16.0, *) {
            return FileManager.default.fileExists(atPath: url.path())
        } else {
            return FileManager.default.fileExists(atPath: url.path)
        }
    }

    private func canAddLog(maxNumberOfDays: Int, lastTimestamp: Double) -> Bool {
        let date = Date(timeIntervalSince1970: lastTimestamp)
        if let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day {
            return days <= maxNumberOfDays
        }
        return false
    }
    
    private func getLogIfPossible(maxNumberOfDays: Int, row: String) -> EventLog? {
        var logs = [EventLog]()
        let values = row.components(separatedBy: commaSeparator)
        let eventLog = EventLog(values)
        if let timestamp = values.first, let timeResult = Double(timestamp) {
            if canAddLog(maxNumberOfDays: maxNumberOfDays, lastTimestamp: timeResult) {
                return eventLog
            }
        }
        return nil
    }
    
    private func createCSV(auditEventLog: EventLog, maxNumberOfDays: Int, persistedCSVContent: String) -> String {
        var logs = [EventLog]()
        do {
            let signature = extractSignatureFrom(csv: persistedCSVContent)
            let contentWithoutSignature = removeSignatureFrom(csv: persistedCSVContent, signature: signature)
        
            // Get rows of the content
            let rows = contentWithoutSignature.components(separatedBy: newLine).filter { !$0.isEmpty }
            
            rows.forEach { row in
                if let log = getLogIfPossible(maxNumberOfDays: maxNumberOfDays, row: row) {
                    logs.append(log)
                }
            }
            var resultantEntries = signature
            let newEntries = getAllEntries(auditEventLog: auditEventLog, logs: logs)
            resultantEntries.append(newEntries)
            return resultantEntries
        }
    }

    // Set the audit Logging File Path if not set.
    private func setPathIfNeeded() {
        do {
            guard auditLoggingFilePath == nil else {
                return
            }
            let fileManager = FileManager.default
            guard let auditLoggingDestinationDirectoryURL = getAuditLoggingDestinationDirectoryURL() else {
                Log.shared.errorAndCrash("Audit logging Destination Directory URL not found")
                return
            }
            
            // Check if destination directory already exists. If not, create it.
            var isDirectory: ObjCBool = true
            if !fileManager.fileExists(atPath: auditLoggingDestinationDirectoryURL.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: auditLoggingDestinationDirectoryURL, withIntermediateDirectories: true)
            }
            
            var url = auditLoggingDestinationDirectoryURL.appendingPathComponent(auditLoggingFileName)
            url = url.appendingPathExtension(csvExtension)
            // Keep the file url
            auditLoggingFilePath = url
        } catch {
            Log.shared.errorAndCrash(error: error)
            return
        }
    }
    
    private func getPersistedCSVContent() -> String? {
        // Set the path where the audit logging file is, if exists, stored.
        setPathIfNeeded()
        do {
            guard let path = auditLoggingFilePath else {
                Log.shared.errorAndCrash("Something really wrong happend")
                return nil
            }
            // If the path exists, the file may or may not exist.
            // Try to get the content of the file as data.
            let data = try Data(contentsOf: path)

            // Convert to string, so it's readable and parseable.
            return String(decoding: data, as: UTF8.self)
        } catch {
            // No such file or directory
            return nil
        }
    }

    /// Convert the content of the CSV to Event Logs.
    private func getLogs(csv: String) -> [EventLog] {
        let rows = csv.components(separatedBy: newLine).filter { !$0.isEmpty }
        var previousLogs = [EventLog]()
        rows.forEach { row in
            let values = row.components(separatedBy: commaSeparator)
            let eventLog = EventLog(values)
            previousLogs.append(eventLog)
        }
        return previousLogs
    }

    /// All entries mean: previous entries + current entry.
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

    private func prependSignatureAndSave(csv: String, signature: String, errorCallback: @escaping (Error) -> Void) {
        var signedCSV = signature
        signedCSV.append(csv)
        saveInDisk(csv: signedCSV, errorCallback: errorCallback)
    }

    private func saveInDisk(csv: String, errorCallback: @escaping (Error) -> Void) {
        do {
            guard let data = csv.data(using: .utf8),
                  let fileUrl = auditLoggingFilePath else {
                Log.shared.errorAndCrash("Can't save CSV file")
                return
            }
            try data.write(to: fileUrl)
            Log.shared.info("CSV file successfully saved")
        } catch {
            errorCallback(error)
            Log.shared.errorAndCrash(error: error)
        }
    }

    // MARK: - Signature

    private func extractBetweenFirstAndLastDashes(input: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: "(-----.*?-----)", options: .dotMatchesLineSeparators)
            let nsString = input as NSString
            if let firstMatch = regex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: nsString.length)),
               let lastMatch = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length)).last {
                let startIndex = firstMatch.range.location
                let endIndex = lastMatch.range.location + lastMatch.range.length
                let contentRange = NSRange(location: startIndex, length: endIndex - startIndex)
                return nsString.substring(with: contentRange)
            }
        } catch {
            Log.shared.errorAndCrash("Error creating regular expression:")
        }
        return nil
    }

    /// Return the signature:
    private func extractSignatureFrom(csv: String) -> String {
        guard let signature = extractBetweenFirstAndLastDashes(input: csv) else {
            return ""
        }
        return signature.appending(newLine)
    }

    private func removeSignatureFrom(csv: String, signature: String) -> String {
        return csv.removeFirstOccurrence(of: signature)
    }

    private func createFirstCSV(auditEventLog: EventLog, errorCallback: @escaping (Error) -> Void) {
        Task {
            let signature = try await signText(text: auditEventLog.entry)
            prependSignatureAndSave(csv: auditEventLog.entry, signature: signature, errorCallback: errorCallback)
        }
    }
}

// MARK: - Private Databases

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
