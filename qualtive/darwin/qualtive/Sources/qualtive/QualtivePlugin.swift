@preconcurrency import Flutter
import QualtiveNative

public class QualtivePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "io.qualtive.qualtive",
      binaryMessenger: registrar.messenger()
    )
    let instance = QualtivePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "fetchEnquiry":
      handleFetchEnquiry(call: call, result: result)
    case "post":
      handlePost(call: call, result: result)
    case "uploadAttachment":
      handleUploadAttachment(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

extension QualtivePlugin {
  fileprivate func handleFetchEnquiry(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let containerId = args["containerId"] as? String,
      let enquiryId = args["enquiryId"] as? String,
      let localeTag = args["locale"] as? String
    else {
      result(
        FlutterError(
          code: "unexpected",
          message: "Invalid fetchEnquiry arguments",
          details: nil
        )
      )
      return
    }

    let previewToken = args["previewToken"] as? String
    let locale = Locale(identifier: localeTag.replacingOccurrences(of: "-", with: "_"))
    let collection = Collection(
      containerId: ContainerId(containerId),
      workspaceId: readWorkspaceId(args["workspaceId"]),
      enquiryId: EnquiryId(enquiryId)
    )

    // FlutterResult is not Sendable; hop back via an unchecked local copy.
    nonisolated(unsafe) let reply = result
    Task {
      let value: Any
      do {
        let enquiry = try await EnquiryController().fetch(
          collection: collection,
          locale: locale,
          previewToken: previewToken
        )
        value = EnquiryChannelMap.encode(enquiry)
      } catch let error as EnquiryController.FetchError {
        value = mapFetchError(error)
      } catch is CancellationError {
        value = FlutterError(code: "unexpected", message: "Cancelled", details: nil)
      } catch {
        value = FlutterError(
          code: "unexpected",
          message: error.localizedDescription,
          details: nil
        )
      }

      await MainActor.run {
        reply(value)
      }
    }
  }

  fileprivate func handlePost(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let containerId = args["containerId"] as? String,
      let enquiryId = args["enquiryId"] as? String,
      let localeTag = args["locale"] as? String,
      let contentRaw = args["content"] as? [Any]
    else {
      result(
        FlutterError(
          code: "unexpected",
          message: "Invalid post arguments",
          details: nil
        )
      )
      return
    }

    let locale = Locale(identifier: localeTag.replacingOccurrences(of: "-", with: "_"))
    let collection = Collection(
      containerId: ContainerId(containerId),
      workspaceId: readWorkspaceId(args["workspaceId"]),
      enquiryId: EnquiryId(enquiryId)
    )
    let user = readUser(args["user"])
    let customAttributes = stringifyAttributes(args["customAttributes"])
    let options = readPostOptions(args["options"])
    let content: [Entry.Content]
    do {
      content = try EntryChannelMap.decode(contentRaw)
    } catch let error as ChannelDecodeError {
      result(FlutterError(code: "unexpected", message: error.message, details: nil))
      return
    } catch {
      result(
        FlutterError(
          code: "unexpected",
          message: error.localizedDescription,
          details: nil
        )
      )
      return
    }

    nonisolated(unsafe) let reply = result
    Task {
      let value: Any
      do {
        let entry = try await PostController().post(
          to: collection,
          content: content,
          user: user,
          customAttributes: customAttributes,
          locale: locale,
          options: options
        )
        value = ["id": entry.id]
      } catch let error as PostController.PostError {
        value = mapPostError(error)
      } catch is CancellationError {
        value = FlutterError(code: "unexpected", message: "Cancelled", details: nil)
      } catch {
        value = FlutterError(
          code: "unexpected",
          message: error.localizedDescription,
          details: nil
        )
      }

      await MainActor.run {
        reply(value)
      }
    }
  }

  fileprivate func handleUploadAttachment(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let containerId = args["containerId"] as? String,
      let contentTypeRaw = args["contentType"] as? String,
      !contentTypeRaw.isEmpty
    else {
      result(
        FlutterError(
          code: "unexpected",
          message: "Invalid uploadAttachment arguments",
          details: nil
        )
      )
      return
    }

    let upload: Attachment.Upload
    let contentType = Attachment.ContentType(contentTypeRaw)
    if let typed = args["bytes"] as? FlutterStandardTypedData {
      upload = .data(typed.data, contentType: contentType)
    } else if let path = args["path"] as? String, !path.isEmpty {
      upload = .file(fileURL(from: path), contentType: contentType)
    } else {
      result(
        FlutterError(
          code: "unexpected",
          message: "Invalid uploadAttachment arguments",
          details: nil
        )
      )
      return
    }

    let workspaceId = readWorkspaceId(args["workspaceId"])
    nonisolated(unsafe) let reply = result
    Task {
      let value: Any
      do {
        let attachment = try await AttachmentController().create(
          from: upload,
          to: ContainerId(containerId),
          workspaceId: workspaceId
        )
        value = ["id": attachment.id]
      } catch let error as AttachmentController.UploadError {
        value = mapUploadError(error)
      } catch is CancellationError {
        value = FlutterError(code: "unexpected", message: "Cancelled", details: nil)
      } catch {
        value = FlutterError(
          code: "unexpected",
          message: error.localizedDescription,
          details: nil
        )
      }

      await MainActor.run {
        reply(value)
      }
    }
  }
}

private func mapFetchError(_ error: EnquiryController.FetchError) -> FlutterError {
  switch error {
  case .notFound:
    return FlutterError(code: "notFound", message: "Not found", details: nil)
  case .network(let networkError):
    return mapNetworkError(networkError)
  }
}

private func mapPostError(_ error: PostController.PostError) -> FlutterError {
  switch error {
  case .enquiryNotFound:
    return FlutterError(code: "notFound", message: "Not found", details: nil)
  case .network(let networkError):
    return mapNetworkError(networkError)
  }
}

private func mapUploadError(_ error: AttachmentController.UploadError) -> FlutterError {
  switch error {
  case .network(let networkError):
    return mapNetworkError(networkError)
  }
}

private func mapNetworkError(_ networkError: NetworkError) -> FlutterError {
  switch networkError {
  case .notFound:
    return FlutterError(code: "notFound", message: "Not found", details: nil)
  case .connection:
    return FlutterError(code: "connection", message: "Connection failed", details: nil)
  case .remoteMaintenance:
    return FlutterError(
      code: "remoteMaintenance",
      message: "Remote maintenance",
      details: nil
    )
  case .unexpected(let underlying):
    return FlutterError(
      code: "unexpected",
      message: underlying.localizedDescription,
      details: nil
    )
  }
}

private enum ChannelDecodeError: Error {
  case invalid(String)

  var message: String {
    switch self {
    case .invalid(let detail):
      return detail
    }
  }
}

private func readWorkspaceId(_ raw: Any?) -> WorkspaceId? {
  guard let string = raw as? String else {
    return nil
  }
  let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
  return trimmed.isEmpty ? nil : WorkspaceId(trimmed)
}

private func readUser(_ raw: Any?) -> User {
  guard let map = raw as? [String: Any] else {
    return User()
  }
  return User(
    id: map["id"] as? String,
    name: map["name"] as? String,
    email: map["email"] as? String
  )
}

private func readPostOptions(_ raw: Any?) -> PostOptions {
  guard let map = raw as? [String: Any] else {
    return PostOptions()
  }
  let metadata: MetadataCollection =
    (map["metadataCollection"] as? String) == "none"
    ? MetadataCollection.none
    : MetadataCollection.nonPersonal
  let consent: UserTrackingConsent =
    (map["userTrackingConsent"] as? String) == "denied"
    ? UserTrackingConsent.denied
    : UserTrackingConsent.granted
  return PostOptions(
    metadataCollection: metadata,
    userTrackingConsent: consent
  )
}

private func stringifyAttributes(_ raw: Any?) -> Attributes {
  guard let map = raw as? [String: Any] else {
    return Attributes()
  }
  var storage: [String: String] = [:]
  for (key, value) in map {
    if let string = stringifyAttributeValue(value) {
      storage[key] = string
    }
  }
  return Attributes(storage)
}

private func stringifyAttributeValue(_ value: Any) -> String? {
  if value is NSNull {
    return nil
  }
  if let string = value as? String {
    return string
  }
  if let number = value as? NSNumber {
    if CFGetTypeID(number) == CFBooleanGetTypeID() {
      return number.boolValue ? "true" : "false"
    }
    let doubleValue = number.doubleValue
    if doubleValue.rounded() == doubleValue {
      return String(number.int64Value)
    }
    return String(doubleValue)
  }
  return nil
}

private func fileURL(from path: String) -> URL {
  if path.hasPrefix("file:") {
    return URL(string: path) ?? URL(fileURLWithPath: path)
  }
  return URL(fileURLWithPath: path)
}

enum EntryChannelMap {
  static func decode(_ raw: [Any]) throws -> [Entry.Content] {
    try raw.map { item in
      guard let map = item as? [String: Any] else {
        throw ChannelDecodeError.invalid("Invalid entry content item")
      }
      return try decodeItem(map)
    }
  }

  private static func decodeItem(_ map: [String: Any]) throws -> Entry.Content {
    guard let type = map["type"] as? String else {
      throw ChannelDecodeError.invalid("Missing entry content type")
    }
    switch type {
    case "title":
      guard let text = map["text"] as? String else {
        throw ChannelDecodeError.invalid("Missing title text")
      }
      return .title(.init(text: text))
    case "score":
      return try decodeScore(map)
    case "text":
      return try decodeText(map)
    case "select":
      return .select(.init(value: map["value"] as? String))
    case "multiselect":
      let values = (map["values"] as? [String]) ?? []
      return .multiselect(.init(values: values))
    case "attachments":
      return .attachments(.init(values: try decodeAttachments(map["values"])))
    default:
      throw ChannelDecodeError.invalid("Unknown entry content type: \(type)")
    }
  }

  private static func decodeScore(_ map: [String: Any]) throws -> Entry.Content {
    let value = try decodeScoreValue(map["value"])
    guard let scoreType = map["scoreType"] as? String else {
      return .score(.init(value: value))
    }
    let kind: Score.Kind
    switch scoreType {
    case "smilies5":
      kind = .smilies5
    case "smilies3":
      kind = .smilies3
    case "thumbs":
      kind = .thumbs
    case "stars5":
      kind = .stars5
    case "nps":
      kind = .nps(
        leadingText: map["leadingText"] as? String ?? "",
        trailingText: map["trailingText"] as? String ?? ""
      )
    default:
      throw ChannelDecodeError.invalid("Unknown scoreType: \(scoreType)")
    }
    var content = Entry.ScoreContent(enquiryContent: Enquiry.ScoreContent(kind: kind))
    content.value = value
    return .score(content)
  }

  private static func decodeScoreValue(_ raw: Any?) throws -> Score? {
    guard let raw else {
      return nil
    }
    let intValue: Int
    if let number = raw as? NSNumber {
      intValue = number.intValue
    } else if let value = raw as? Int {
      intValue = value
    } else {
      throw ChannelDecodeError.invalid("Invalid score value")
    }
    guard (0...100).contains(intValue) else {
      throw ChannelDecodeError.invalid("Score value must be between 0 and 100")
    }
    return Score(intValue)
  }

  private static func decodeText(_ map: [String: Any]) throws -> Entry.Content {
    let value = map["value"] as? String
    guard let storage = map["storageTarget"] as? [String: Any] else {
      return .text(.init(value: value))
    }
    let target: Enquiry.TextContent.StorageTarget
    switch storage["type"] as? String {
    case "text":
      target = .text
    case "attribute":
      guard let attribute = storage["attribute"] as? String else {
        throw ChannelDecodeError.invalid("Missing attribute name")
      }
      target = .attribute(attribute)
    default:
      throw ChannelDecodeError.invalid("Unknown storageTarget type")
    }
    var content = Entry.TextContent(
      enquiryContent: Enquiry.TextContent(storageTarget: target)
    )
    content.value = value
    return .text(content)
  }

  private static func decodeAttachments(_ raw: Any?) throws -> [Attachment] {
    guard let list = raw as? [Any] else {
      return []
    }
    return try list.map { item in
      guard let map = item as? [String: Any] else {
        throw ChannelDecodeError.invalid("Invalid attachment reference")
      }
      let id: UInt64
      if let number = map["id"] as? NSNumber {
        id = number.uint64Value
      } else if let value = map["id"] as? Int {
        id = UInt64(value)
      } else {
        throw ChannelDecodeError.invalid("Missing attachment id")
      }
      return Attachment(id: id)
    }
  }
}

enum EnquiryChannelMap {
  static func encode(_ enquiry: Enquiry) -> [String: Any] {
    [
      "id": enquiry.id,
      "slug": enquiry.slug,
      "name": enquiry.name,
      "pages": enquiry.pages.map(encodePage),
      "submittedPages": enquiry.submittedPages.map(encodeSubmittedPage),
      "theme": encodeTheme(enquiry.theme),
      "container": encodeContainer(enquiry.container),
      "isUserContactDetailsRequired": enquiry.isUserContactDetailsRequired,
    ]
  }

  private static func encodePage(_ page: Enquiry.Page) -> [String: Any] {
    ["content": page.content.map(encodePageContent)]
  }

  private static func encodePageContent(_ content: Enquiry.Content) -> [String: Any] {
    switch content {
    case .title(let value):
      return ["type": "title", "text": value.text]
    case .body(let value):
      return ["type": "body", "text": value.text]
    case .image(let value):
      return [
        "type": "image",
        "attachment": ["url": value.attachment.url],
      ]
    case .score(let value):
      return encodeScore(value)
    case .text(let value):
      var object: [String: Any] = [
        "type": "text",
        "storageTarget": encodeStorageTarget(value.storageTarget),
      ]
      if let placeholder = value.placeholder {
        object["placeholder"] = placeholder
      } else {
        object["placeholder"] = NSNull()
      }
      return object
    case .select(let value):
      return [
        "type": "select",
        "options": value.options,
        "allowsCustomInput": value.allowsCustomInput,
      ]
    case .multiselect(let value):
      return [
        "type": "multiselect",
        "options": value.options,
      ]
    case .attachments:
      return ["type": "attachments"]
    case .contactDetails(let value):
      var object: [String: Any] = [
        "type": "contactDetails",
        "title": value.title,
      ]
      if let placeholder = value.placeholder {
        object["placeholder"] = placeholder
      } else {
        object["placeholder"] = NSNull()
      }
      return object
    }
  }

  private static func encodeScore(_ content: Enquiry.ScoreContent) -> [String: Any] {
    switch content.kind {
    case .smilies5:
      return [
        "type": "score",
        "scoreType": "smilies5",
        "leadingText": NSNull(),
        "trailingText": NSNull(),
      ]
    case .smilies3:
      return [
        "type": "score",
        "scoreType": "smilies3",
        "leadingText": NSNull(),
        "trailingText": NSNull(),
      ]
    case .thumbs:
      return [
        "type": "score",
        "scoreType": "thumbs",
        "leadingText": NSNull(),
        "trailingText": NSNull(),
      ]
    case .stars5:
      return [
        "type": "score",
        "scoreType": "stars5",
        "leadingText": NSNull(),
        "trailingText": NSNull(),
      ]
    case .nps(let leadingText, let trailingText):
      return [
        "type": "score",
        "scoreType": "nps",
        "leadingText": leadingText,
        "trailingText": trailingText,
      ]
    }
  }

  private static func encodeStorageTarget(
    _ target: Enquiry.TextContent.StorageTarget
  ) -> [String: Any] {
    switch target {
    case .text:
      return ["type": "text"]
    case .attribute(let attribute):
      return ["type": "attribute", "attribute": attribute]
    }
  }

  private static func encodeSubmittedPage(_ page: Enquiry.SubmittedPage) -> [String: Any] {
    [
      "content": page.content.map(encodeSubmittedContent),
      "conditions": page.conditions.map(encodeCondition),
    ]
  }

  private static func encodeSubmittedContent(
    _ content: Enquiry.SubmittedPage.Content
  ) -> [String: Any] {
    switch content {
    case .title(let value):
      return ["type": "title", "text": value.text]
    case .body(let value):
      return ["type": "body", "text": value.text]
    case .image(let value):
      var object: [String: Any] = [
        "type": "image",
        "attachment": ["url": value.attachment.url],
      ]
      if let linkURL = value.linkURL {
        object["linkURL"] = linkURL
      } else {
        object["linkURL"] = NSNull()
      }
      return object
    case .confirmationText(let value):
      return ["type": "confirmationText", "text": value.text]
    case .name:
      return ["type": "name"]
    case .userInput:
      return ["type": "userInput"]
    case .userInputScore:
      return ["type": "userInputScore"]
    case .link(let value):
      return ["type": "link", "text": value.text, "url": value.url]
    case .reviewLinks(let value):
      return [
        "type": "reviewLinks",
        "links": value.links.map { link -> [String: Any] in
          var object: [String: Any] = [
            "title": link.title,
            "url": link.url,
          ]
          if let logo = link.logo {
            object["logo"] = [
              "urlVector": logo.urlVector,
              "urlVectorDark": logo.urlVectorDark,
            ]
          } else {
            object["logo"] = NSNull()
          }
          if let icon = link.icon {
            object["icon"] = [
              "urlRaster": icon.urlRaster,
              "urlRasterDark": icon.urlRasterDark,
            ]
          } else {
            object["icon"] = NSNull()
          }
          return object
        },
      ]
    }
  }

  private static func encodeCondition(
    _ condition: Enquiry.SubmittedPage.Condition
  ) -> [String: Any] {
    switch condition {
    case .score(let score):
      return [
        "type": "score",
        "ranges": score.ranges.map { range -> [String: Any] in
          [
            "lower": range.lower as Any? ?? NSNull(),
            "upper": range.upper as Any? ?? NSNull(),
          ]
        },
      ]
    }
  }

  private static func encodeTheme(_ theme: Enquiry.Theme) -> [String: Any] {
    [
      "background": encodeBackground(theme.background),
      "font": encodeFont(theme.font),
      "cornerStyle": theme.cornerStyle == .rounded ? "rounded" : "square",
      "isBackgroundAttachmentVisibleInResponses":
        theme.isBackgroundAttachmentVisibleInResponses,
      "isBackgroundColorVisibleInResponses": theme.isBackgroundColorVisibleInResponses,
    ]
  }

  private static func encodeBackground(_ background: Enquiry.Theme.Background) -> [String: Any] {
    switch background {
    case .predefined(let value):
      let raw: String
      switch value {
      case .plain: raw = "plain"
      case .sponda: raw = "sponda"
      }
      return ["type": "predefined", "value": raw]
    case .custom(let custom):
      var object: [String: Any] = [
        "type": "custom",
        "color": ["value": custom.color.value],
      ]
      if let attachment = custom.attachment {
        object["attachment"] = [
          "id": attachment.id,
          "contentType": attachment.contentType,
          "url": attachment.url,
        ]
      } else {
        object["attachment"] = NSNull()
      }
      return object
    }
  }

  private static func encodeFont(_ font: Enquiry.Theme.Font) -> [String: Any] {
    switch font {
    case .predefined(let value):
      return ["type": "predefined", "value": value]
    case .custom(let url):
      return ["type": "custom", "url": url]
    }
  }

  private static func encodeContainer(_ container: Enquiry.Container) -> [String: Any] {
    [
      "id": container.id,
      "isWhiteLabel": container.isWhiteLabel,
      "customLogos": container.customLogos.map { logo -> [String: Any] in
        [
          "size": logo.size == .wide ? "wide" : "square",
          "intendedBackground": logo.intendedBackground == .light ? "light" : "dark",
          "primaryColor": logo.primaryColor,
          "urlVector": logo.urlVector,
        ]
      },
      "visibilityMode": container.visibilityMode == .public ? "public" : "private",
    ]
  }

  static func encodeSampleEnquiry() -> [String: Any] {
    encode(
      Enquiry(
        id: 1,
        slug: "flutter",
        name: "Flutter",
        pages: [
          Enquiry.Page(
            content: [
              .title(.init(text: "Hello")),
              .score(.init(kind: .stars5)),
              .score(.init(kind: .nps(leadingText: "Bad", trailingText: "Good"))),
            ]
          )
        ],
        theme: Enquiry.Theme(
          background: .predefined(.plain),
          font: .predefined("default"),
          cornerStyle: .rounded
        ),
        container: Enquiry.Container(
          id: "ci-test",
          visibilityMode: .private
        )
      )
    )
  }
}
