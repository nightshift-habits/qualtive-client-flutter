import XCTest
@testable import qualtive

class RunnerTests: XCTestCase {
  func testPluginExists() {
    XCTAssertNotNil(QualtivePlugin())
  }

  func testEnquiryChannelMapEncodesSample() {
    let map = EnquiryChannelMap.encodeSampleEnquiry()
    XCTAssertEqual(map["slug"] as? String, "flutter")
    XCTAssertEqual(map["name"] as? String, "Flutter")
    XCTAssertEqual(map["id"] as? Int64, 1)

    let pages = map["pages"] as? [[String: Any]]
    let content = pages?.first?["content"] as? [[String: Any]]
    XCTAssertEqual(content?[0]["type"] as? String, "title")
    XCTAssertEqual(content?[0]["text"] as? String, "Hello")
    XCTAssertEqual(content?[1]["scoreType"] as? String, "stars5")
    XCTAssertEqual(content?[2]["scoreType"] as? String, "nps")
    XCTAssertEqual(content?[2]["leadingText"] as? String, "Bad")
    XCTAssertEqual(content?[2]["trailingText"] as? String, "Good")

    let theme = map["theme"] as? [String: Any]
    XCTAssertEqual(theme?["cornerStyle"] as? String, "rounded")
    let container = map["container"] as? [String: Any]
    XCTAssertEqual(container?["id"] as? String, "ci-test")
    XCTAssertEqual(container?["visibilityMode"] as? String, "private")
  }
}
