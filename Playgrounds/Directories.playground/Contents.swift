import Cocoa
import Foundation

var str = "Hello, playground"

let constants = [
    FileManager.SearchPathDirectory.applicationDirectory: "NSApplicationDirectory",
    FileManager.SearchPathDirectory.demoApplicationDirectory: "NSDemoApplicationDirectory",
    FileManager.SearchPathDirectory.developerApplicationDirectory: "NSDeveloperApplicationDirectory",
    FileManager.SearchPathDirectory.adminApplicationDirectory: "NSAdminApplicationDirectory",
    FileManager.SearchPathDirectory.libraryDirectory: "NSLibraryDirectory",
    FileManager.SearchPathDirectory.developerDirectory: "NSDeveloperDirectory",
    FileManager.SearchPathDirectory.userDirectory: "NSUserDirectory",
    FileManager.SearchPathDirectory.documentationDirectory: "NSDocumentationDirectory",
    FileManager.SearchPathDirectory.documentDirectory: "NSDocumentDirectory",
    FileManager.SearchPathDirectory.coreServiceDirectory: "NSCoreServiceDirectory",
    FileManager.SearchPathDirectory.autosavedInformationDirectory: "NSAutosavedInformationDirectory",
    FileManager.SearchPathDirectory.desktopDirectory: "NSDesktopDirectory",
    FileManager.SearchPathDirectory.cachesDirectory: "NSCachesDirectory",
    FileManager.SearchPathDirectory.applicationSupportDirectory: "NSApplicationSupportDirectory",
    FileManager.SearchPathDirectory.downloadsDirectory: "NSDownloadsDirectory",
    FileManager.SearchPathDirectory.moviesDirectory: "NSMoviesDirectory",
    FileManager.SearchPathDirectory.musicDirectory: "NSMusicDirectory",
    FileManager.SearchPathDirectory.picturesDirectory: "NSPicturesDirectory",
    FileManager.SearchPathDirectory.printerDescriptionDirectory: "NSPrinterDescriptionDirectory",
    FileManager.SearchPathDirectory.sharedPublicDirectory: "NSSharedPublicDirectory",
    FileManager.SearchPathDirectory.preferencePanesDirectory: "NSPreferencePanesDirectory",
    FileManager.SearchPathDirectory.itemReplacementDirectory: "NSItemReplacementDirectory",
    FileManager.SearchPathDirectory.allApplicationsDirectory: "NSAllApplicationsDirectory",
    FileManager.SearchPathDirectory.allLibrariesDirectory: "NSAllLibrariesDirectory",
    FileManager.SearchPathDirectory.trashDirectory: "NSTrashDirectory",
]

let fm = FileManager.default

for (k, v) in constants {
    print("\(v) => \(fm.urls(for: k, in: .userDomainMask))")
}
