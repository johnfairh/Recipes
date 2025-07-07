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

    /// Model container init - shared by extensions and app
    static var minimalModelContainer: ModelContainer = {
        do {
            let modelConfiguration = ModelConfiguration(storeName, groupContainer: .identifier(appGroupName))

            let modelContainer = try ModelContainer(
                for: Schema(versionedSchema: CurrentSchema.self),
                migrationPlan: MigrationPlan.self,
                configurations: modelConfiguration
            )
            Log.log("Using database \(modelContainer.configurations.first!.url.path)")
            return modelContainer
        } catch {
            Log.log("Model init failed, falling back to in-memory: \(error)") // XXX logging
            let memoryConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(
                for: Schema(versionedSchema: CurrentSchema.self),
                configurations: memoryConfiguration
            )
        }
    }()

    @MainActor
    static var intentsModelContext: ModelContext {
        minimalModelContainer.mainContext
    }

    /// Model container init - for app, understands reset + import
    @MainActor
    static var modelContainer: ModelContainer = {
        importExport.checkForReset()
        importExport.checkForImport()

        let modelContainer = minimalModelContainer

        modelContainer.mainContext.undoManager = UndoManager()

        return modelContainer
    }()

    static func createObjects(modelContext: ModelContext) {
        let purple = Book(shortName: "Purple", longName: "Purple exercise book", symbolName: "book.closed", hasPageNumbers: true, sortOrder: 0)
        let brain = Book(shortName: "Brain", longName: "Traditional recipes", symbolName: "brain.head.profile", hasPageNumbers: false, sortOrder: 1)

        let pasta = Recipe(name: "Pasta", book: brain, pageNumber: nil, url: nil, kind: .meal, servingsCount: 2, quantity: nil, isImported: true, notes: "")

        let soup = Recipe(name: "Chilli Soup", book: purple, pageNumber: 22, url: nil, kind: .meal, servingsCount: 4, quantity: nil, isImported: true, notes: "")
        let risotto = Recipe(name: "Risotto", book: purple, pageNumber: 13, url: nil, kind: .meal, servingsCount: 3, quantity: nil, isImported: false, notes: "")

        let cake = Recipe(name: "Chocolate Cake", book: purple, pageNumber: 100, url: nil, kind: .sweet, servingsCount: nil, quantity: "8x8 inch tray", isImported: false, notes: "")
        cake.lastCookedTime = Date.now

        let nuts = Recipe(name: "Bar nuts", book: purple, pageNumber: 125, url: "https://bbc.co.uk/", kind: .other, servingsCount: nil, quantity: "A handful", isImported: true, notes: "Here are some notes about bar nuts.  I made this for a Dorking Christmas trip once, and they came out well - all eaten, decent comments.")
        nuts.lastCookedTime = .now.addingTimeInterval(-(60 * 60 * 24 * 7))

        let nutsCooking = Cooking(recipe: nuts, notes: nil, timestamp: nuts.lastCookedTime!.addingTimeInterval(-(60*60*24*7)))

        modelContext.insert(brain)
        modelContext.insert(purple)

        modelContext.insert(pasta)
        modelContext.insert(soup)
        modelContext.insert(risotto)
        modelContext.insert(cake)
        modelContext.insert(nutsCooking)
        modelContext.insert(nuts)

        do {
           try modelContext.save()
        } catch {
            Log.log("Failed to save model context: \(error)")
        }
    }
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

    // Dunno why but we don't get an 'Application Support' directory any more... Xcode 26 / iOS 26 thing?
    private func initAppContainerPath() {
        try! FileManager.default.createDirectory(at: appContainerURL, withIntermediateDirectories: true)
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

    // Reset - set up so that next time we start the app, the real DB will be erased
    // before we start up

    static let resetFilename = "RESET"

    var resetFileURL: URL {
        appContainerURL.appending(component: Self.resetFilename)
    }

    func testAndClearReset() -> Bool {
        let resetFile = resetFileURL
        defer { try? FileManager.default.removeItem(at: resetFile) }
        return FileManager.default.fileExists(atPath: resetFile.path)
    }

    func reset() {
        Log.log("Reset - touching file \(resetFileURL.path)")
        FileManager.default.createFile(atPath: resetFileURL.path, contents: nil)
    }

    func checkForReset() {
        initAppContainerPath()
        let reset = testAndClearReset()
        Log.log("Import - reset required: \(reset)")
        guard reset else { return }

        let fileURLs = matchingFiles(in: groupContainerURL)
        delete(fileURLs: fileURLs)
        Log.log("Import - reset - deleted files: \(fileURLs.map(\.lastPathComponent))")
    }
}
