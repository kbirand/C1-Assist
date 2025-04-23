//
//  DatabaseManager.swift
//  C1 Assist
//
//  Created by Cascade on 23/04/2025.
//

import Foundation
import SQLite3

enum DatabaseError: Error {
    case connectionFailed
    case prepareFailed
    case stepFailed
    case bindFailed
    case queryFailed
    
    var localizedDescription: String {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the database."
        case .prepareFailed:
            return "Failed to prepare the SQL statement."
        case .stepFailed:
            return "Failed to execute the SQL statement."
        case .bindFailed:
            return "Failed to bind parameters to the SQL statement."
        case .queryFailed:
            return "Failed to execute the database query."
        }
    }
}

class DatabaseManager {
    private var db: OpaquePointer?
    
    /// Initialize a database connection
    /// - Parameter path: Path to the SQLite database file
    /// - Throws: DatabaseError if connection fails
    init(path: String) throws {
        if sqlite3_open(path, &db) != SQLITE_OK {
            throw DatabaseError.connectionFailed
        }
    }
    
    /// Close the database connection
    func close() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
    
    /// Add folder paths to the ZPATHLOCATION table
    /// - Parameters:
    ///   - folderCount: Number of folders to add
    ///   - startingPK: Starting primary key value
    /// - Throws: DatabaseError if any database operation fails
    func addFolderPaths(folderCount: Int, startingPK: Int = 6) throws {
        // First, check if the table exists
        if !tableExists(tableName: "ZPATHLOCATION") {
            print("ZPATHLOCATION table does not exist")
            throw DatabaseError.queryFailed
        }
        
        // Prepare the SQL statement
        let insertSQL = """
        INSERT INTO ZPATHLOCATION 
        (Z_ENT, Z_PK, ZRELATIVEPATH, ZISRELATIVE, ZVOLUME, ZWINROOT, ZWINATTRIBUTE) 
        VALUES (?, ?, ?, ?, ?, NULL, NULL)
        """
        
        var statement: OpaquePointer?
        
        // Prepare the statement
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("Error preparing statement: \(errorMessage)")
            throw DatabaseError.prepareFailed
        }
        
        // Add each folder path
        for i in 1...folderCount {
            let pk = startingPK + (i - 1)
            let folderNumberString = String(format: "%02d", i)
            let relativePath = "Capture/\(folderNumberString)"
            
            // Bind parameters
            sqlite3_bind_int(statement, 1, 38)  // Z_ENT
            sqlite3_bind_int(statement, 2, Int32(pk))  // Z_PK
            sqlite3_bind_text(statement, 3, (relativePath as NSString).utf8String, -1, nil)  // Z_RELATIVEPATH
            sqlite3_bind_int(statement, 4, 1)  // Z_ISRELATIVE
            sqlite3_bind_text(statement, 5, "", -1, nil)  // Z_VOLUME (empty)
            
            // Execute the statement
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Error inserting data: \(errorMessage)")
                sqlite3_finalize(statement)
                throw DatabaseError.stepFailed
            }
            
            // Reset the statement for the next insertion
            sqlite3_reset(statement)
        }
        
        // Finalize the statement
        sqlite3_finalize(statement)
    }
    
    /// Check if a table exists in the database
    /// - Parameter tableName: Name of the table to check
    /// - Returns: Boolean indicating if the table exists
    private func tableExists(tableName: String) -> Bool {
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(tableName)'"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return false
        }
        
        let result = sqlite3_step(statement) == SQLITE_ROW
        sqlite3_finalize(statement)
        
        return result
    }
    
    /// Get the highest Z_PK value from the ZPATHLOCATION table
    /// - Returns: The highest Z_PK value, or the default starting value if the table is empty
    func getHighestPK() -> Int {
        let query = "SELECT MAX(Z_PK) FROM ZPATHLOCATION"
        var statement: OpaquePointer?
        var highestPK = 5  // Default starting value - 1
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                highestPK = Int(sqlite3_column_int(statement, 0))
            }
        }
        
        sqlite3_finalize(statement)
        return highestPK
    }
    
    deinit {
        close()
    }
}
