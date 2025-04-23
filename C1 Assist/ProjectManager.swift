//
//  ProjectManager.swift
//  C1 Assist
//
//  Created by Cascade on 23/04/2025.
//

import Foundation

enum ProjectError: Error {
    case invalidProjectName
    case failedToCreateDirectory
    case failedToCopyDatabase
    case databaseNotFound
    case databaseUpdateFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidProjectName:
            return "Project name cannot be empty or contain invalid characters."
        case .failedToCreateDirectory:
            return "Failed to create project directory structure."
        case .failedToCopyDatabase:
            return "Failed to copy the database file."
        case .databaseNotFound:
            return "The main.db file was not found."
        case .databaseUpdateFailed:
            return "Failed to update the database with folder information."
        }
    }
}

class ProjectManager {
    private let mainFolders = ["Capture", "Output", "Selects", "Trash"]
    
    /// Creates a project with the specified name, folder count, and location
    /// - Parameters:
    ///   - name: The name of the project
    ///   - folderCount: The number of empty folders to create in the Capture directory
    ///   - location: The location where the project will be created
    /// - Throws: ProjectError if any step of the project creation fails
    func createProject(name: String, folderCount: Int, location: URL) throws {
        // Validate project name
        guard !name.isEmpty, !name.contains("/") else {
            throw ProjectError.invalidProjectName
        }
        
        // Create project directory
        let projectURL = location.appendingPathComponent(name)
        
        do {
            // Check if we have write access to the location
            let fileManager = FileManager.default
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: location.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                // Location exists and is a directory, check if we can write to it
                let testFileURL = location.appendingPathComponent("write_test_\(UUID().uuidString).tmp")
                do {
                    try "test".write(to: testFileURL, atomically: true, encoding: .utf8)
                    try fileManager.removeItem(at: testFileURL)
                    print("Write access confirmed for location: \(location.path)")
                } catch {
                    print("No write access to location: \(location.path), error: \(error)")
                    throw ProjectError.failedToCreateDirectory
                }
            }
            
            // Create the project directory
            print("Creating project directory at: \(projectURL.path)")
            try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true, attributes: nil)
            
            // Create main folders
            for folderName in mainFolders {
                let folderURL = projectURL.appendingPathComponent(folderName)
                print("Creating folder: \(folderURL.path)")
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                
                // Create empty folders in Capture directory
                if folderName == "Capture" {
                    for i in 1...folderCount {
                        // Format the folder name with leading zeros (01, 02, 03, etc.)
                        let folderNumberString = String(format: "%02d", i)
                        let emptyFolderURL = folderURL.appendingPathComponent(folderNumberString)
                        print("Creating empty folder: \(emptyFolderURL.path)")
                        try fileManager.createDirectory(at: emptyFolderURL, withIntermediateDirectories: true, attributes: nil)
                    }
                }
            }
            
            // Copy and rename the main.db file
            let dbDestinationURL = try copyDatabaseFile(to: projectURL, withName: name)
            
            // Update the database with folder paths
            try updateDatabase(at: dbDestinationURL, folderCount: folderCount)
            
        } catch {
            print("Error creating project: \(error), \(error.localizedDescription)")
            throw ProjectError.failedToCreateDirectory
        }
    }
    
    /// Copies the main.db file to the project directory and renames it to projectname.cosessiondb
    /// - Parameters:
    ///   - projectURL: The URL of the project directory
    ///   - projectName: The name of the project
    /// - Throws: ProjectError if the database file cannot be found or copied
    /// - Returns: URL of the copied database file
    private func copyDatabaseFile(to projectURL: URL, withName projectName: String) throws -> URL {
        // Direct path to the main.db file that we know exists
        let directDBPath = "/Users/koraybirand/Desktop/C1 Assist/C1 Assist/main.db"
        let directDBURL = URL(fileURLWithPath: directDBPath)
        
        let destinationURL = projectURL.appendingPathComponent("\(projectName).cosessiondb")
        
        if FileManager.default.fileExists(atPath: directDBPath) {
            print("Found database at direct path: \(directDBPath)")
            try FileManager.default.copyItem(at: directDBURL, to: destinationURL)
            return destinationURL
        }
        
        // Get the path to the main.db file
        // First, try to find it in the app bundle
        let fileManager = FileManager.default
        
        // Get the main app directory path
        let mainAppDirectory = Bundle.main.bundleURL.deletingLastPathComponent()
        let possibleDBPath = mainAppDirectory.appendingPathComponent("C1 Assist/main.db")
        
        if fileManager.fileExists(atPath: possibleDBPath.path) {
            print("Found database at: \(possibleDBPath.path)")
            try fileManager.copyItem(at: possibleDBPath, to: destinationURL)
            return destinationURL
        }
        
        // If we're here, we need to search for the file
        print("Searching for main.db file...")
        
        // Get the current working directory
        let currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        print("Current directory: \(currentDirectoryURL.path)")
        
        // Try to find the main.db file in the project directory structure
        let projectDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
        print("Project directory: \(projectDirectoryURL.path)")
        
        // Search in common locations
        var searchLocations = [
            projectDirectoryURL,
            projectDirectoryURL.appendingPathComponent("C1 Assist"),
            Bundle.main.bundleURL,
            currentDirectoryURL
        ]
        
        // Add resource URL if available
        if let resourceURL = Bundle.main.resourceURL {
            searchLocations.append(resourceURL)
        }
        
        for location in searchLocations {
            let dbURL = location.appendingPathComponent("main.db")
            print("Checking: \(dbURL.path)")
            
            if fileManager.fileExists(atPath: dbURL.path) {
                print("Found database at: \(dbURL.path)")
                try fileManager.copyItem(at: dbURL, to: destinationURL)
                return destinationURL
            }
        }
        
        // If we get here, we couldn't find the database file
        print("Could not find main.db file in any expected location")
        throw ProjectError.databaseNotFound
    }
    
    /// Update the database with folder paths
    /// - Parameters:
    ///   - dbURL: URL of the database file
    ///   - folderCount: Number of folders to add to the database
    /// - Throws: ProjectError if database update fails
    private func updateDatabase(at dbURL: URL, folderCount: Int) throws {
        do {
            let dbManager = try DatabaseManager(path: dbURL.path)
            defer { dbManager.close() }
            
            // Get the highest PK value to start from
            let startingPK = dbManager.getHighestPK() + 1
            print("Starting PK for new folder entries: \(startingPK)")
            
            // Add folder paths to the database
            try dbManager.addFolderPaths(folderCount: folderCount, startingPK: startingPK)
            print("Successfully updated database with \(folderCount) folder paths")
        } catch {
            print("Error updating database: \(error)")
            throw ProjectError.databaseUpdateFailed
        }
    }
}
