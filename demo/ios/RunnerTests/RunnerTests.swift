import XCTest
@testable import qualtive

class RunnerTests: XCTestCase {
  func testPluginExists() {
    XCTAssertNotNil(QualtivePlugin())
  }
}
