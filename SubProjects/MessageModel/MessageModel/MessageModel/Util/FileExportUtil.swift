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
        case emptyString
        case filepathNotFound
    }

    public func save(auditEventLog: EventLog, maxLogTime: Int, errorCallback: @escaping (Error) -> Void) {
        // 1. Check if the CSV file already exists.
        let csvFileAlreadyExists = csvFileAlreadyExists()

        // 2. Craft the CVS.
        // - if it exists already, add a row.
        // - Otherwise, create it with the given row.
        guard let csv = createCSV(auditEventLog: auditEventLog, csvFileAlreadyExists: csvFileAlreadyExists, maxLogTime: maxLogTime) else {
            Log.shared.error("CSV not saved. Probably filepath not found")
            errorCallback(SignError.filepathNotFound)
            return
        }

        if csvFileAlreadyExists {
            // Get rows of the content
            var rows = csv.components(separatedBy: newLine).filter { !$0.isEmpty }
            rows = rows.dropLast(2)

            // Convert strings to EventLog (objects)
            var logs = [EventLog]()
            rows.forEach { row in
                let values = row.components(separatedBy: commaSeparator)
                let eventLog = EventLog(values)
                logs.append(eventLog)
            }

            // All entries means: previous entries + current entry.
            let previousEntries: [String] = logs.compactMap { $0.entry.trimmed() }
            var allEntries = previousEntries
            allEntries.append(auditEventLog.entry)
            let result = allEntries.joined(separator: newLine)

            signAndSave(csv: result, errorCallback: errorCallback)

        } else {
            signAndSave(csv: csv, errorCallback: errorCallback)
        }
    }
    
    private func signAndSave(csv: String, errorCallback: @escaping (Error) -> Void) {
        getSignature(text: csv) { error in
            errorCallback(error)
        } successCallback: { [weak self] signature in
            guard let me = self else {
                Log.shared.error(error: "Lost Myself")
                return
            }
            me.save(csv: csv, signature: signature)
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

    private func createCSV(auditEventLog: EventLog, csvFileAlreadyExists: Bool, maxLogTime: Int) -> String? {
        var logs = [EventLog]()
        do {
            if !csvFileAlreadyExists {
                return auditEventLog.entry
            } else {
                guard let filePath = auditLoggingFilePath else {
                    Log.shared.errorAndCrash("File path not found")
                    return nil
                }
                // Get the content of the file as data.
                let data = try Data(contentsOf: filePath)

                // Convert to string, so it's readable and parseable.
                let content = String(decoding: data, as: UTF8.self)

                // Get rows of the content
                let rows = content.components(separatedBy: newLine).filter { !$0.isEmpty }

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

                // All entries means: previous entries + current entry.
                let previousEntries: [String] = logs.compactMap { $0.entry.trimmed() }
                var allEntries = previousEntries
                allEntries.append(auditEventLog.entry)
                return allEntries.joined(separator: newLine)
            }
        } catch {
            Log.shared.errorAndCrash("Something went wrong while creating the CVS")
        }
        Log.shared.errorAndCrash("Something went wrong while creating the CVS")
        return ""
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

extension FileExportUtil {

    private func getSignature(text: String, errorCallback: @escaping (Error) -> Void, successCallback: @escaping (String) -> Void) {
        guard !text.isEmpty else {
            Log.shared.errorAndCrash("Invalid argument: an empty string can't be signed")
            errorCallback(SignError.emptyString)
            return
        }
        PEPSession().signText(text) { error in
            errorCallback(error)
        } successCallback: { signature in
            successCallback(signature)
        }
    }
    
    private func save(csv: String, signature: String) {
        // 3. Append the signature at the end of the file.
        var signedCSV = csv
        signedCSV.append(newLine)
        signedCSV.append(signature)

        // 4. Save the file in disk.
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
}
