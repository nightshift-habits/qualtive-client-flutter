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
}

private func mapFetchError(_ error: EnquiryController.FetchError) -> FlutterError {
  switch error {
  case .notFound:
    return FlutterError(code: "notFound", message: "Not found", details: nil)
  case .network(let networkError):
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
