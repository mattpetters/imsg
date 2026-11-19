import Foundation
import IMsgCore

extension RPCServer {
  func handleContactsPhoto(params: [String: Any], id: Any?) async throws {
    let params = try RPCParameters(params, method: "contacts.photo", supportedKeys: ["handle"])
    let handle = try params.string("handle") ?? ""
    guard !handle.isEmpty else {
      throw RPCError.invalidParams("handle is required")
    }
    let photo = contactResolver.photo(for: handle)
    var result: [String: Any] = ["handle": handle, "mime_type": NSNull(), "data": NSNull()]
    if let photo {
      result["mime_type"] = photo.mimeType
      result["data"] = photo.data.base64EncodedString()
    }
    respond(id: id, result: result)
  }
}
