//
//  DBsUtil.swift
//  pEp
//
//  Created by Martín Brude on 12/1/22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//
import pEpIOSToolbox
import pEp4iosIntern

class DBsUtil: NSObject {

    /// Export keys.db, management.db, system.db
    ///
    /// - Throws: throws an error in cases of failure.
    public static func exportDatabases() throws {

        let managementDBFileName = "management.db"
        let keysDBFileName = "keys.db"
        let systemDBFileName = "system.db"
        let securityPEPsqliteFileName = "security.pEp.sqlite"

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

            //Get the destination path of each file
            var managementDestinationURL = URL(string: destinationDirectoryURL.absoluteString)
            managementDestinationURL?.appendPathComponent(managementDBFileName)
            guard let managementDBDestinationPath = managementDestinationURL?.path else {
                Log.shared.errorAndCrash("Management DB Destination Directory URL not found")
                return
            }

            var keysDestinationURL = URL(string: destinationDirectoryURL.absoluteString)
            keysDestinationURL?.appendPathComponent(keysDBFileName)
            guard let keysDBDestinationPath = keysDestinationURL?.path else {
                Log.shared.errorAndCrash("Keys DB Destination Directory URL not found")
                return
            }

            var systemDestinationURL = URL(string: destinationDirectoryURL.absoluteString)
            systemDestinationURL?.appendPathComponent(systemDBFileName)
            guard let systemDBDestinationPath = systemDestinationURL?.path else {
                Log.shared.errorAndCrash("Keys DB Destination Directory URL not found")
                return
            }

            var securityPEPsqliteDestinationURL = URL(string: destinationDirectoryURL.absoluteString)
            securityPEPsqliteDestinationURL?.appendPathComponent(securityPEPsqliteFileName)
            guard let securityPEPsqliteDestinationPath = securityPEPsqliteDestinationURL?.path else {
                Log.shared.errorAndCrash("security.pEp.sqlite DB Destination Directory URL not found")
                return
            }
            
            //Copy Items from source paths to the destination paths.
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
            
            //PEP Security SQLite DB
            if let pepSecuritySQLiteDBsourcePath = getSQLiteDBSourceURL()?.path {
                try FileManager.default.copyItem(atPath: pepSecuritySQLiteDBsourcePath, toPath: securityPEPsqliteDestinationPath)
            }
        }
    }
}

//MARK: - Private

extension DBsUtil {

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

    /// - Returns: retrieves the URL where the system.db file is stored
    private static func getSystemDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("pEp_home")
        appGroupURL.appendPathComponent("system.db")
        return appGroupURL
    }

    /// - Returns: retrieves the URL where the security.pEp.sqlite file is stored
    private static func getSQLiteDBSourceURL() -> URL? {
        guard var appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kAppGroupIdentifier) else {
            Log.shared.errorAndCrash("Container folder not found")
            return nil
        }
        appGroupURL.appendPathComponent("security.pEp.sqlite")
        return appGroupURL
    }

    /// - Returns: Retrieves the date as string using the date format YYYYMMDD-hh-mm.
    private static func getDatetimeAsString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMDD-hh-mm"
        return dateFormatter.string(from: date)
    }

}
