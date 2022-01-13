//
//  FileExportUtil.swift
//  MessageModel
//
//  Created by Martín Brude on 13/1/22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox
import pEp4iosIntern

public class FileExportUtil: NSObject {

    /// Export databases
    ///
    /// - Throws: throws an error in cases of failure.
    public static func exportDatabases() throws {
        let managementDBFileName = "management.db"
        let keysDBFileName = "keys.db"
        let systemDBFileName = "system.db"
//        let securityPEPsqliteFileName = "security.pEp.sqlite"

        //app containerDir/security.pEp.*

        do {
            guard let destinationDirectoryURL: URL = getDBDestinationDirectoryURL() else {
                Log.shared.errorAndCrash("Destination Directory URL not found")
                return
            }
            //Check if destination directory already exists. If not, create it.
            var isDirectory:ObjCBool = true
            if !FileManager.default.fileExists(atPath: destinationDirectoryURL.path, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
            }

            //Get the destination path of each file and copy Items from source paths to the destination paths
            let managementDBDestinationPath = getDestinationPath(from: destinationDirectoryURL, withFileName: managementDBFileName)
            let keysDBDestinationPath = getDestinationPath(from: destinationDirectoryURL, withFileName: keysDBFileName)
            let systemDBDestinationPath = getDestinationPath(from: destinationDirectoryURL, withFileName: systemDBFileName)

            //Management DB
            if let managementDBsourcePath = getSourceURLforHiddenFileNamed(name: managementDBFileName)?.path {
                try FileManager.default.copyItem(atPath: managementDBsourcePath, toPath: managementDBDestinationPath)
            }
            //Keys DB
            if let keyDBsourcePath = getSourceURLforHiddenFileNamed(name: keysDBFileName)?.path {
                try FileManager.default.copyItem(atPath: keyDBsourcePath, toPath: keysDBDestinationPath)
            }
            //System DB
            if let systemDBsourcePath = getSystemDBSourceURL()?.path {
                try FileManager.default.copyItem(atPath: systemDBsourcePath, toPath: systemDBDestinationPath)
            }
            //security.pEp DB
            if let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier)?.path,
               let items = try? FileManager.default.contentsOfDirectory(atPath: path) {
                let filesNames = items.filter { $0.contains("security.pEp") }
                try? filesNames.forEach { fileName in
                    let securityPEPsqliteDestinationPath = getDestinationPath(from: destinationDirectoryURL, withFileName: fileName)
                    if let pepSecuritySQLiteDBsourcePath = getSQLiteDBSourceURL(fileName: fileName)?.path {
                        try FileManager.default.copyItem(atPath: pepSecuritySQLiteDBsourcePath, toPath: securityPEPsqliteDestinationPath)
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
    private static func getDestinationPath(from url: URL, withFileName fileName: String) -> String {
        var copyFileName = fileName
        if fileName.starts(with: ".") {
            copyFileName.removeFirst()
        }
        var urlCopy = URL(string: url.absoluteString)
        urlCopy?.appendPathComponent(copyFileName)
        guard let path = urlCopy?.path else {
            Log.shared.errorAndCrash("Management DB Destination Directory URL not found")
            return ""
        }
        return path
    }

    /// - Returns: The destination directory url.
    /// The last path component indicates the date and time.
    /// It could be something like '.../Documents/db-export/{YYYYMMDD-hh-mm}/'
    private static func getDBDestinationDirectoryURL() -> URL? {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard var docUrl = documentsUrl else {
            Log.shared.errorAndCrash("Documents not found")
            return nil
        }
        docUrl.appendPathComponent("db-export")
        docUrl.appendPathComponent("\(getDatetimeAsString())")
        return docUrl
    }

    /// Retrieve the url of the hidden file passed by param if it's stored in the shared group.
    ///
    /// - Parameter name: The name of the file to look for.
    /// - Returns: The URL if the file exists. Nil otherwise.
    private static func getSourceURLforHiddenFileNamed(name: String) -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("pEp_home/.pEp/")
        appGroupURL.appendPathComponent(name)
        return appGroupURL
    }

    /// - Returns: the URL where the system.db file is stored
    private static func getSystemDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("pEp_home")
        appGroupURL.appendPathComponent("system.db")
        return appGroupURL
    }

    /// - Returns: the URL where the security.pEp.sqlite file is stored
    private static func getSQLiteDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("security.pEp.sqlite")
        return appGroupURL
    }

    /// - Returns: the URL where the security.pEp.sqlite file is stored
    private static func getSQLiteDBSourceURL(fileName: String) -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent(fileName)
        return appGroupURL
    }

    /// - Returns: the URL where the security.pEp.sqlite file is stored
    private static func getSQLiteSHMDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("security.pEp.sqlite-shm")
        return appGroupURL
    }

    /// - Returns: the URL where the security.pEp.sqlite file is stored
    private static func getSQLiteWALBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("security.pEp.sqlite-wal")
        return appGroupURL
    }

    /// - Returns: the date as string using the date format YYYYMMDD-hh-mm.
    private static func getDatetimeAsString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMDD-hh-mm"
        return dateFormatter.string(from: date)
    }
}
