import Foundation
import IMsgCore
import Testing

@testable import imsg

private struct PhotoResolver: ContactResolving {
  let contactsUnavailable = false
  func displayName(for handle: String) -> String? { nil }
  func displayNames(for handles: [String]) -> [String: String] { [:] }
  func searchByName(_ query: String) -> [ContactMatch] { [] }
  func photo(for handle: String) -> ContactPhoto? {
    handle == "+14155550111" ? ContactPhoto(imageData: Data([0xFF, 0xD8, 0xFF, 0xE0])) : nil
  }
}

@Test
func rpcContactsPhotoReturnsBase64AndNullsWhenAbsent() async throws {
  let store = try CommandTestDatabase.makeStoreForRPC()
  let output = TestRPCOutput()
  let server = RPCServer(
    store: store, verbose: false, output: output, contactResolver: PhotoResolver())

  await server.handleLineForTesting(
    #"{"jsonrpc":"2.0","id":1,"method":"contacts.photo","params":{"handle":"+14155550111"}}"#)
  await server.handleLineForTesting(
    #"{"jsonrpc":"2.0","id":2,"method":"contacts.photo","params":{"handle":"+14155550999"}}"#)

  let found = output.responses.first?["result"] as? [String: Any]
  #expect(found?["handle"] as? String == "+14155550111")
  #expect(found?["mime_type"] as? String == "image/jpeg")
  #expect(found?["data"] as? String == Data([0xFF, 0xD8, 0xFF, 0xE0]).base64EncodedString())
  let missing = output.responses.last?["result"] as? [String: Any]
  #expect(missing?["handle"] as? String == "+14155550999")
  #expect(missing?["mime_type"] is NSNull)
  #expect(missing?["data"] is NSNull)
}

@Test
func rpcContactsPhotoRequiresHandleAndRejectsUnknownKeys() async throws {
  let store = try CommandTestDatabase.makeStoreForRPC()
  let output = TestRPCOutput()
  let server = RPCServer(store: store, verbose: false, output: output)

  await server.handleLineForTesting(
    #"{"jsonrpc":"2.0","id":1,"method":"contacts.photo","params":{}}"#)
  await server.handleLineForTesting(
    #"{"jsonrpc":"2.0","id":2,"method":"contacts.photo","params":{"handle":"a","x":1}}"#)

  #expect(output.errors.count == 2)
}
