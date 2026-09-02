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

  func testEntryChannelMapDecodesContent() throws {
    let content = try EntryChannelMap.decode(
      [
        ["type": "title", "text": "Hello"],
        [
          "type": "score",
          "value": 75,
          "scoreType": "stars5",
          "leadingText": "Bad",
          "trailingText": "Good",
        ],
        [
          "type": "text",
          "value": "Hi",
          "storageTarget": ["type": "attribute", "attribute": "Age"],
        ],
        ["type": "select", "value": "A"],
        ["type": "multiselect", "values": ["X", "Y"]],
        ["type": "attachments", "values": [["id": 99]]],
      ]
    )

    XCTAssertEqual(content.count, 6)

    guard case .title(let title) = content[0] else {
      return XCTFail("expected title")
    }
    XCTAssertEqual(title.text, "Hello")

    guard case .score(let score) = content[1] else {
      return XCTFail("expected score")
    }
    XCTAssertEqual(score.value, 75)
    XCTAssertEqual(score.definition.kind, .stars5)

    guard case .text(let text) = content[2] else {
      return XCTFail("expected text")
    }
    XCTAssertEqual(text.value, "Hi")
    XCTAssertEqual(text.definition.storageTarget, .attribute("Age"))

    guard case .select(let select) = content[3] else {
      return XCTFail("expected select")
    }
    XCTAssertEqual(select.value, "A")

    guard case .multiselect(let multi) = content[4] else {
      return XCTFail("expected multiselect")
    }
    XCTAssertEqual(multi.values, ["X", "Y"])

    guard case .attachments(let attachments) = content[5] else {
      return XCTFail("expected attachments")
    }
    XCTAssertEqual(attachments.values.map(\.id), [99])
  }
}
