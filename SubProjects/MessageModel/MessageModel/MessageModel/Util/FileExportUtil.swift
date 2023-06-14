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

public protocol FileExportUtilProtocol: AnyObject {
    func exportDatabases() throws
    func save(auditLog: AuditLog, maxLogSize: Double)
}

public class FileExportUtil: NSObject, FileExportUtilProtocol {

    // MARK: - Singleton

    static public let shared = FileExportUtil()

    private override init() { }
    
    private let planckFolderName = "planck"
    private let auditLoggingFileName = "auditLogging"
    private let csvExtension = "csv"
    private let commaSeparator = ", "
    private let newLine = "\n"
    private var auditLogginFilePath: URL?
    
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

    /// - Returns: the date as string using the date format YYYYMMDD-hh-mm.
    private func getDatetimeAsString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMDD-hh-mm"
        return dateFormatter.string(from: date)
    }
}

//MARK: - Audit Loggin

extension FileExportUtil {

    public func save(auditLog: AuditLog, maxLogSize: Double) {
        // 1. Check if the CSV file already exists.
        let csvExists = csvExists()

        // 2. Craft the CVS.
        // - if it exists already, add a row.
        // - Otherwise, create it with the given row.
        let csv = createCSV(auditLog: auditLog, fileAlreadyExists: csvExists, maxLogSize: maxLogSize)

        // 3. Save the file in disk.
        do {
            guard let data = csv.data(using: .utf8),
                  let fileUrl = auditLogginFilePath else {
                Log.shared.errorAndCrash("Can't save cvs")
                return
            }
            try data.write(to: fileUrl)
            Log.shared.info("CSV successfully saved")
            NSLog("\n\n\n\n\n \(fileUrl.absoluteString) \n\n\n\n\n")
        } catch {
            Log.shared.errorAndCrash(error: error)
        }
    }
}

//MARK: - Private - Audit Loggin

extension FileExportUtil {

    private func csvExists() -> Bool {
        do {
            let fileManager = FileManager.default
            guard let auditLogginDestinationDirectoryURL = getAuditLogginDestinationDirectoryURL() else {
                Log.shared.errorAndCrash("Audit loggin Destination Directory URL not found")
                return false
            }

            // Check if destination directory already exists. If not, create it.
            var isDirectory: ObjCBool = true
            if !fileManager.fileExists(atPath: auditLogginDestinationDirectoryURL.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: auditLogginDestinationDirectoryURL, withIntermediateDirectories: true)
            }

            var url = auditLogginDestinationDirectoryURL.appendingPathComponent(auditLoggingFileName)
            url = url.appendingPathExtension(csvExtension)
            // Keep the file url
            auditLogginFilePath = url

            // Check if the file already exists.
            var fileExists: Bool = false
            if #available(iOS 16.0, *) {
                if fileManager.fileExists(atPath: url.path()) {
                    fileExists = true
                }
            } else {
                fileExists = fileManager.fileExists(atPath: url.path)
            }
            return fileExists

        } catch {
            Log.shared.errorAndCrash(error: error)
            return false
        }
    }

    private func createCSV(auditLog: AuditLog, fileAlreadyExists: Bool, maxLogSize: Double) -> String {
        var logs = [AuditLog]()
        do {
            if !fileAlreadyExists {
                return auditLog.entry
            } else {
                guard let filePath = auditLogginFilePath else {
                    Log.shared.errorAndCrash("File path not found")
                    return ""
                }
                // Get the content of the file as data.
                let data = try Data(contentsOf: filePath)
                
                // Convert to string, so it's readable and parseable.
                let content = String(decoding: data, as: UTF8.self)
                
                // Get rows of the content (exclude the header).
                let rows = content.components(separatedBy: newLine).filter { !$0.isEmpty }

                // Convert strings to Audit Logs (objects)
                rows.forEach { row in
                    guard row.count > 3 else {
                        Log.shared.errorAndCrash("Invalid row. Should not happen")
                        return
                    }
                    let rowValues = row.components(separatedBy: commaSeparator)
                    let log = AuditLog(timestamp: rowValues[0],
                                       subject: rowValues[1],
                                       senderId: rowValues[2],
                                       rating: rowValues[3])
                    logs.append(log)
                }

                // All entries means: previous entries + current entry.
                let previousEntries = logs.compactMap { $0.entry }
                var allEntries = previousEntries
                allEntries.append(auditLog.entry)
                if data.megabytes > maxLogSize {
                    allEntries = allEntries.dropFirst().map { $0 }
                }
                return allEntries.joined(separator: newLine)
            }
        } catch {
            Log.shared.errorAndCrash("Something went wrong while creating the CVS")
        }
        Log.shared.errorAndCrash("Something went wrong while creating the CVS")
        return ""
    }

    /// - Returns: The destination directory url.
    private func getAuditLogginDestinationDirectoryURL() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docUrl = documentsUrl else {
            Log.shared.errorAndCrash("Documents not found")
            return nil
        }
        return docUrl
    }
}
