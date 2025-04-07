import Foundation
import Security

struct CodeSigningRequirement {
  let data: Data

  var requirement: SecRequirement? {
    var requirement: SecRequirement?
    let createRequirementStatus = SecRequirementCreateWithData(data as CFData, [], &requirement)
    guard createRequirementStatus == errSecSuccess, let requirement else {
      return nil
    }
    return requirement
  }
}

extension CodeSigningRequirement: CustomStringConvertible {
  var description: String {
    guard let requirement else {
      return "<Invalid CodeSigningRequirement>"
    }
    var cfstr: CFString?
    let copyStringStatus = SecRequirementCopyString(requirement, [], &cfstr)
    guard copyStringStatus == errSecSuccess, let cfstr else {
      return "<Invalid CodeSigningRequirement>"
    }
    return cfstr as String
  }
}

extension Client {
  var staticCode: SecStaticCode? {
    guard let url = self.url else { return nil }
    var staticCode: SecStaticCode?
    let createStaticCodeStatus = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
    guard createStaticCodeStatus == errSecSuccess, let staticCode else {
      return nil
    }
    return staticCode
  }

  func checkValidity(requirement: Data) -> Bool {
    let requirement = CodeSigningRequirement(data: requirement)
    return self.checkValidity(requirement: requirement)
  }

  func checkValidity(requirement: CodeSigningRequirement) -> Bool {
    guard let staticCode = self.staticCode, let requirement = requirement.requirement else {
      return false
    }
    let verifyStatus = SecStaticCodeCheckValidity(staticCode, [], requirement)
    return verifyStatus == errSecSuccess
  }
}
