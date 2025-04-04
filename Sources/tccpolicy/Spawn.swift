import Darwin.C
import Foundation
import PosixSpawnResponsible

enum SpawnError: Error {
  case spawnFailed(code: Int32, description: String)
  case waitFailed(code: Int32)
}

func spawnWithDisclaim(_ args: [String]) async throws -> Int32 {
  guard !args.isEmpty else {
    throw SpawnError.spawnFailed(code: EINVAL, description: "No command specified")
  }

  let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
  defer { for case let arg? in argv { free(arg) } }

  let env: [UnsafeMutablePointer<CChar>?] = []
  defer { for case let arg? in env { free(arg) } }

  var fileActions: posix_spawn_file_actions_t?
  posix_spawn_file_actions_init(&fileActions)
  defer { posix_spawn_file_actions_destroy(&fileActions) }

  var attr: posix_spawnattr_t?
  posix_spawnattr_init(&attr)
  defer { posix_spawnattr_destroy(&attr) }

  let disclaimResult = responsibility_spawnattrs_setdisclaim(&attr, true)
  if disclaimResult != 0 {
    throw SpawnError.spawnFailed(
      code: disclaimResult,
      description: "Failed to set disclaim attribute"
    )
  }

  var pid = pid_t()
  let rv = posix_spawnp(&pid, argv[0], &fileActions, &attr, argv + [nil], env + [nil])
  if rv != 0 {
    throw SpawnError.spawnFailed(
      code: rv,
      description: String(cString: strerror(rv))
    )
  }

  var status: Int32 = 0
  let waitResult = waitpid(pid, &status, 0)
  if waitResult == -1 {
    throw SpawnError.waitFailed(code: errno)
  }

  let exitStatus = (Int32(status) >> 8) & 0xFF
  let signalStatus = Int32(status) & 0x7F
  let hasExited = signalStatus == 0
  let wasSignaled = signalStatus > 0 && signalStatus != 0x7F

  if hasExited {
    return exitStatus
  } else if wasSignaled {
    return 128 + signalStatus
  }

  return status
}
