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
    case executeError(String)

    var description: String {
      switch self {
      case .openError(let message):
        return "Failed to open database: \(message)"
      case .executeError(let message):
        return "Failed to execute statement: \(message)"
      }
    }
  }

  func open(readonly: Bool = true) throws {
    precondition(self.db == nil, "Database already open")

    guard
      sqlite3_open_v2(url.path, &db, readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE, nil)
        == SQLITE_OK
    else {
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

  func execute(sql: String) throws -> Int32 {
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

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let errorMessage = String(cString: sqlite3_errmsg(db))
      throw Error.executeError(errorMessage)
    }

    return sqlite3_changes(db)
  }

  func clients() throws -> [String] {
    return query(sql: "SELECT DISTINCT client FROM access").map { $0["client"] as? String ?? "" }
  }

  enum AuthValue: Int64 {
    case denied = 0
    case unknown = 1
    case allowed = 2
    case addOnly = 4
  }

  func authValue(client: String, service: Service, identifierPrefix: String? = nil) -> AuthValue? {
    let sql: String

    if let identifierPrefix {
      sql = """
          SELECT auth_value FROM access WHERE client = '\(client)' AND service = '\(service.tccServiceConstant)' AND indirect_object_identifier LIKE '\(identifierPrefix)%';
        """
    } else {
      sql = """
          SELECT auth_value FROM access WHERE client = '\(client)' AND service = '\(service.tccServiceConstant)';
        """
    }

    let rows = query(sql: sql)
    guard let row = rows.first else {
      return nil
    }

    guard let authValue = row["auth_value"] as? Int64 else {
      assertionFailure("Could not cast auth_value to Int64")
      return nil
    }

    return AuthValue(rawValue: authValue)
  }

  func identifiers(client: String, service: Service) -> [String] {
    let sql = """
        SELECT indirect_object_identifier FROM access WHERE client = '\(client)' AND service = '\(service.tccServiceConstant)';
      """
    return query(sql: sql).map { $0["indirect_object_identifier"] as? String ?? "" }
  }

  func reset(client: String, service: Service? = nil) throws -> Int32 {
    let sql: String
    if let service {
      sql = """
          DELETE FROM access WHERE client = '\(client)' AND service = '\(service.tccServiceConstant)';
        """
    } else {
      sql = """
          DELETE FROM access WHERE client = '\(client)';
        """
    }
    return try execute(sql: sql)
  }
}
