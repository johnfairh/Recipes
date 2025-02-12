//
//  DatabaseLoader.swift
//  Recipes
//
//  Created by John on 11/02/2025.
//

import SwiftData
import Foundation

enum DatabaseLoader {
    private static let storeName = "RecipeStore"
    static let appGroupName = "group.tml.Recipes"

    static let importExport = AppGroupImportExport(appGroup: appGroupName, filePrefix: storeName)

    static var modelContainer: ModelContainer = {
        importExport.checkForImport()

        let modelConfiguration = ModelConfiguration(storeName, groupContainer: .identifier(appGroupName))

        let schema = Schema([
            Item.self,
        ])

        Log.log("123")

        do {
            let modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            Log.log("Using database \(modelContainer.configurations.first!.url.path)")
            return modelContainer
        }
        catch {
            Log.log("Model init failed, falling back to in-memory: \(error)") // XXX logging
            let memoryConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: memoryConfiguration)
        }
    }()
}

// macOS
//  Using database               /Users/johnf/Library/Group Containers/group.tml.Recipes/Library/Application Support/RecipeStore.store
//  Import - app group container /Users/johnf/Library/Group Containers/group.tml.Recipes/Library/Application Support
//  Import - app container       /Users/johnf/Library/Containers/tml.Recipes/Data/Library/Application Support
// iOS Using database /private/var/mobile/Containers/Shared/AppGroup/D09D01BD-AC87-4E2C-BCB6-9B577D51FD61/Library/Application Support/RecipeStore.store


/// Manage import & export of the database files.
///
/// This is for debug and development: Xcode lets you pull off the app's own container, but it's not possible
/// to even access the group containers where the database goes.  This thing enables two actions:
///
/// 1) Export - prompted by something in the UI to call `AppGroupImportExport.export`.
///   This copies *all* files from the app group's 'Library/Application Support' directory with the "store prefix"
///   into the app's directory of the same name, with the added suffix of "exported".
///
/// 2) Import - called during app init *before* doing anything about core data.
///   This copies *all* files from the app's directory that have the "store prefix" but _do not_ have the "exported"
///   suffix into the app group directory, and then deletes these files.
struct AppGroupImportExport {
    let appGroup: String
    let filePrefix: String

    static let exportedSuffix = "exported"

    var appContainerURL: URL {
        try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }

    var groupContainerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            preconditionFailure("Can't get app group container URL.")
        }
        return url
            .appending(component: "Library", directoryHint: .isDirectory)
            .appending(component: "Application Support", directoryHint: .isDirectory)
    }

    private func matchingFiles(in url: URL) -> [URL] {
        var result: [URL] = []
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants) else {
            preconditionFailure("Can't enumerate path: \(url.path)")
        }
        while let fileURL = enumerator.nextObject() as? URL,
              case let filename = fileURL.lastPathComponent {
            if filename.hasPrefix(filePrefix) && !filename.hasSuffix(".\(Self.exportedSuffix)") {
                result.append(fileURL)
            }
        }
        return result
    }

    private func copy(fileURLs: [URL], to url: URL, suffix: String = "") {
        for fileURL in fileURLs {
            let destination = url.appendingPathComponent(fileURL.lastPathComponent)
                .appendingPathExtension(suffix)
            try? FileManager.default.removeItem(at: destination)
            try! FileManager.default.copyItem(at: fileURL, to: destination)
        }
    }

    private func delete(fileURLs: [URL]) {
        for fileURL in fileURLs {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    init(appGroup: String, filePrefix: String) {
        self.appGroup = appGroup
        self.filePrefix = filePrefix
    }

    func checkForImport() {
        Log.log("Import - app group container \(groupContainerURL.path)")
        Log.log("Import - app container \(appContainerURL.path)")
        guard case let fileURLs = matchingFiles(in: appContainerURL), !fileURLs.isEmpty else {
            Log.log("Import - no app group file import required")
            return
        }
        copy(fileURLs: fileURLs, to: groupContainerURL)
        delete(fileURLs: fileURLs)
        Log.log("Import - imported files into app group container: \(fileURLs.map(\.lastPathComponent))")
    }

    func export() {
        Log.log("Export - app group container \(groupContainerURL.path)")
        Log.log("Export - app container \(appContainerURL.path)")
        guard case let fileURLs = matchingFiles(in: groupContainerURL), !fileURLs.isEmpty else {
            Log.log("Export - no app group export required")
            return
        }
        copy(fileURLs: fileURLs, to: appContainerURL, suffix: Self.exportedSuffix)
        Log.log("Export - exported files: \(fileURLs.map(\.lastPathComponent))")
    }
}
