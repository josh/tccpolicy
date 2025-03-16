import Foundation
import SQLite3

actor TCCDb {
  private let url: URL
  private var db: OpaquePointer?

  static let systemURL: URL = {
    return URL(fileURLWithPath: "/Library")
      .appendingPathComponent("Application Support")
      .appendingPathComponent("com.apple.TCC")
      .appendingPathComponent("TCC.db")
  }()

  static let userURL: URL = {
    return FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library")
      .appendingPathComponent("Application Support")
      .appendingPathComponent("com.apple.TCC")
      .appendingPathComponent("TCC.db")
  }()

  static let system: TCCDb = TCCDb(url: systemURL)
  static let user: TCCDb = TCCDb(url: userURL)

  private init(url: URL) {
    self.url = url
  }

  enum Error: Swift.Error, CustomStringConvertible {
    case openError(String)

    var description: String {
      switch self {
      case .openError(let message):
        return "Failed to open database: \(message)"
      }
    }
  }

  func open() throws {
    precondition(self.db == nil, "Database already open")

    guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
      let errorMessage = String(cString: sqlite3_errmsg(db))
      if let db = self.db {
        sqlite3_close(db)
        self.db = nil
      }
      throw Error.openError(errorMessage)
    }
  }

  func close() {
    guard self.db != nil else { return }
    sqlite3_close(self.db)
    self.db = nil
  }

  func query(sql: String) -> [[String: Any]] {
    guard let db = db else {
      preconditionFailure("Database not open")
    }

    var statement: OpaquePointer?
    defer {
      if statement != nil {
        sqlite3_finalize(statement)
      }
    }

    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let errorMessage = String(cString: sqlite3_errmsg(db))
      preconditionFailure("Failed to prepare statement: \(errorMessage)")
    }

    var results: [[String: Any]] = []

    while sqlite3_step(statement) == SQLITE_ROW {
      var row: [String: Any] = [:]

      let columnCount = sqlite3_column_count(statement)

      for i in 0..<columnCount {
        let columnName = String(cString: sqlite3_column_name(statement, i))

        let columnType = sqlite3_column_type(statement, i)

        switch columnType {
        case SQLITE_INTEGER:
          let value = sqlite3_column_int64(statement, i)
          row[columnName] = value

        case SQLITE_TEXT:
          if let cString = sqlite3_column_text(statement, i) {
            let value = String(cString: cString)
            row[columnName] = value
          }

        case SQLITE_BLOB:
          if let blob = sqlite3_column_blob(statement, i) {
            let size = sqlite3_column_bytes(statement, i)
            let data = Data(bytes: blob, count: Int(size))
            row[columnName] = data
          }

        case SQLITE_NULL:
          row[columnName] = nil

        default:
          fatalError("Unknown column type: \(columnType)")
        }
      }

      results.append(row)
    }

    return results
  }

  func count(sql: String) -> Int64 {
    guard let db = db else {
      preconditionFailure("Database not open")
    }

    var statement: OpaquePointer?
    defer {
      if statement != nil {
        sqlite3_finalize(statement)
      }
    }

    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let errorMessage = String(cString: sqlite3_errmsg(db))
      preconditionFailure("Failed to prepare statement: \(errorMessage)")
    }

    assert(sqlite3_step(statement) == SQLITE_ROW)
    assert(sqlite3_column_count(statement) == 1)
    assert(sqlite3_column_type(statement, 0) == SQLITE_INTEGER)
    return sqlite3_column_int64(statement, 0)
  }

  func hasAccess(client: String, service: String, identifier: String? = nil) throws -> Bool {
    let sql = """
        SELECT COUNT(*) FROM access WHERE client = '\(client)' AND service = '\(service)' AND auth_value = 2;
      """
    return count(sql: sql) > 0
  }
}
