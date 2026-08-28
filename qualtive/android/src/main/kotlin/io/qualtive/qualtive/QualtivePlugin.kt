package io.qualtive.qualtive

import android.content.Context
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.qualtive.AttachmentContentType
import io.qualtive.Container
import io.qualtive.Enquiry
import io.qualtive.MetadataCollection
import io.qualtive.Page
import io.qualtive.PostOptions
import io.qualtive.Qualtive
import io.qualtive.QualtiveConfig
import io.qualtive.QualtiveException
import io.qualtive.ScoreType
import io.qualtive.SubmittedPage
import io.qualtive.Theme
import io.qualtive.User
import io.qualtive.UserTrackingConsent
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale

class QualtivePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null
    private var scope: CoroutineScope? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        channel =
            MethodChannel(binding.binaryMessenger, "io.qualtive.qualtive").also {
                it.setMethodCallHandler(this)
            }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        scope?.cancel()
        scope = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "fetchEnquiry" -> handleFetchEnquiry(call, result)
            "post" -> handlePost(call, result)
            "uploadAttachment" -> handleUploadAttachment(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleFetchEnquiry(call: MethodCall, result: MethodChannel.Result) {
        val context = applicationContext
        val activeScope = scope
        if (context == null || activeScope == null) {
            result.error("unexpected", "Plugin not attached", null)
            return
        }

        val containerId = call.argument<String>("containerId")
        val enquiryId = call.argument<String>("enquiryId")
        val localeTag = call.argument<String>("locale")
        val previewToken = call.argument<String>("previewToken")

        if (containerId.isNullOrBlank() || enquiryId.isNullOrBlank() || localeTag.isNullOrBlank()) {
            result.error("unexpected", "Invalid fetchEnquiry arguments", null)
            return
        }

        activeScope.launch {
            try {
                val client = createClient(context, containerId, localeTag)
                val enquiry = client.fetchEnquiry(enquiryId, previewToken)
                result.success(EnquiryChannelMap.encode(enquiry))
            } catch (_: CancellationException) {
                return@launch
            } catch (error: Exception) {
                replyError(result, error)
            }
        }
    }

    private fun handlePost(call: MethodCall, result: MethodChannel.Result) {
        val context = applicationContext
        val activeScope = scope
        if (context == null || activeScope == null) {
            result.error("unexpected", "Plugin not attached", null)
            return
        }

        val containerId = call.argument<String>("containerId")
        val enquiryId = call.argument<String>("enquiryId")
        val localeTag = call.argument<String>("locale")
        val contentRaw = call.argument<List<*>>("content")

        if (containerId.isNullOrBlank() || enquiryId.isNullOrBlank() || localeTag.isNullOrBlank() ||
            contentRaw == null
        ) {
            result.error("unexpected", "Invalid post arguments", null)
            return
        }

        activeScope.launch {
            try {
                val client = createClient(context, containerId, localeTag)
                val entry =
                    client.post(
                        enquiryId = enquiryId,
                        content = EntryChannelMap.decode(contentRaw),
                        user = readUser(call.argument("user")),
                        customAttributes = readCustomAttributes(call.argument("customAttributes")),
                        options = readPostOptions(call.argument("options")),
                    )
                result.success(mapOf("id" to entry.id))
            } catch (_: CancellationException) {
                return@launch
            } catch (error: Exception) {
                replyError(result, error)
            }
        }
    }

    private fun handleUploadAttachment(call: MethodCall, result: MethodChannel.Result) {
        val context = applicationContext
        val activeScope = scope
        if (context == null || activeScope == null) {
            result.error("unexpected", "Plugin not attached", null)
            return
        }

        val containerId = call.argument<String>("containerId")
        val localeTag = call.argument<String>("locale")
        val contentTypeRaw = call.argument<String>("contentType")
        val bytes = call.argument<ByteArray>("bytes")
        val path = call.argument<String>("path")

        if (containerId.isNullOrBlank() || localeTag.isNullOrBlank() || contentTypeRaw.isNullOrBlank()) {
            result.error("unexpected", "Invalid uploadAttachment arguments", null)
            return
        }
        if (bytes == null && path.isNullOrBlank()) {
            result.error("unexpected", "Invalid uploadAttachment arguments", null)
            return
        }

        val contentType = AttachmentContentType(contentTypeRaw)
        activeScope.launch {
            try {
                val client = createClient(context, containerId, localeTag)
                val attachment =
                    if (bytes != null) {
                        client.uploadAttachment(bytes = bytes, contentType = contentType)
                    } else {
                        client.uploadAttachment(
                            uri = uriFromPath(path!!),
                            contentType = contentType,
                        )
                    }
                result.success(mapOf("id" to attachment.id))
            } catch (_: CancellationException) {
                return@launch
            } catch (error: Exception) {
                replyError(result, error)
            }
        }
    }
}

private fun createClient(
    context: Context,
    containerId: String,
    localeTag: String,
): Qualtive =
    Qualtive(
        context = context,
        containerId = containerId,
        config = QualtiveConfig(locale = Locale.forLanguageTag(localeTag)),
    )

private fun replyError(result: MethodChannel.Result, error: Exception) {
    when (error) {
        is QualtiveException.NotFound ->
            result.error("notFound", error.message ?: "Not found", null)
        is QualtiveException.Connection ->
            result.error("connection", error.message ?: "Connection failed", null)
        is QualtiveException.RemoteMaintenance ->
            result.error(
                "remoteMaintenance",
                error.message ?: "Remote maintenance",
                null,
            )
        is QualtiveException.Unexpected ->
            result.error("unexpected", error.message ?: "Unexpected error", null)
        else -> result.error("unexpected", error.message ?: "Unexpected error", null)
    }
}

private fun readUser(raw: Any?): User? {
    val map = raw as? Map<*, *> ?: return null
    return User(
        id = map["id"] as? String,
        name = map["name"] as? String,
        email = map["email"] as? String,
    )
}

private fun readCustomAttributes(raw: Any?): Map<String, Any> {
    val map = raw as? Map<*, *> ?: return emptyMap()
    val result = linkedMapOf<String, Any>()
    for ((key, value) in map) {
        if (key is String && value != null) {
            result[key] = value
        }
    }
    return result
}

private fun readPostOptions(raw: Any?): PostOptions {
    val map = raw as? Map<*, *> ?: return PostOptions()
    val metadata =
        when (map["metadataCollection"] as? String) {
            "none" -> MetadataCollection.None
            else -> MetadataCollection.NonPersonal
        }
    val consent =
        when (map["userTrackingConsent"] as? String) {
            "denied" -> UserTrackingConsent.Denied
            else -> UserTrackingConsent.Granted
        }
    return PostOptions(
        metadataCollection = metadata,
        userTrackingConsent = consent,
    )
}

private fun uriFromPath(path: String): Uri =
    if (path.startsWith("content:") || path.startsWith("file:")) {
        Uri.parse(path)
    } else {
        Uri.fromFile(File(path))
    }

internal object EnquiryChannelMap {
    fun encode(enquiry: Enquiry): Map<String, Any?> =
        mapOf(
            "id" to enquiry.id,
            "slug" to enquiry.slug,
            "name" to enquiry.name,
            "pages" to enquiry.pages.map(::encodePage),
            "submittedPages" to enquiry.submittedPages.map(::encodeSubmittedPage),
            "theme" to encodeTheme(enquiry.theme),
            "container" to encodeContainer(enquiry.container),
            "isUserContactDetailsRequired" to enquiry.isUserContactDetailsRequired,
        )

    private fun encodePage(page: Page): Map<String, Any?> =
        mapOf("content" to page.content.map(::encodePageContent))

    private fun encodePageContent(content: Page.Content): Map<String, Any?> =
        when (content) {
            is Page.Content.Title ->
                mapOf(
                    "type" to "title",
                    "text" to content.text,
                )

            is Page.Content.Body ->
                mapOf(
                    "type" to "body",
                    "text" to content.text,
                )

            is Page.Content.Image ->
                mapOf(
                    "type" to "image",
                    "attachment" to mapOf("url" to content.attachment.url),
                )

            is Page.Content.Score ->
                mapOf(
                    "type" to "score",
                    "scoreType" to content.scoreType.toApiValue(),
                    "leadingText" to content.leadingText,
                    "trailingText" to content.trailingText,
                )

            is Page.Content.Text ->
                mapOf(
                    "type" to "text",
                    "placeholder" to content.placeholder,
                    "storageTarget" to encodeStorageTarget(content.storageTarget),
                )

            is Page.Content.Select ->
                mapOf(
                    "type" to "select",
                    "options" to content.options,
                    "allowsCustomInput" to content.allowsCustomInput,
                )

            is Page.Content.Multiselect ->
                mapOf(
                    "type" to "multiselect",
                    "options" to content.options,
                )

            is Page.Content.Attachments -> mapOf("type" to "attachments")

            is Page.Content.ContactDetails ->
                mapOf(
                    "type" to "contactDetails",
                    "title" to content.title,
                    "placeholder" to content.placeholder,
                )
        }

    private fun encodeStorageTarget(target: Page.Content.Text.StorageTarget): Map<String, Any?> =
        when (target) {
            is Page.Content.Text.StorageTarget.Text -> mapOf("type" to "text")

            is Page.Content.Text.StorageTarget.Attribute ->
                mapOf(
                    "type" to "attribute",
                    "attribute" to target.attribute,
                )
        }

    private fun encodeSubmittedPage(page: SubmittedPage): Map<String, Any?> =
        mapOf(
            "content" to page.content.map(::encodeSubmittedContent),
            "conditions" to page.conditions.map(::encodeCondition),
        )

    private fun encodeSubmittedContent(content: SubmittedPage.Content): Map<String, Any?> =
        when (content) {
            is SubmittedPage.Content.Title ->
                mapOf("type" to "title", "text" to content.text)

            is SubmittedPage.Content.Body ->
                mapOf("type" to "body", "text" to content.text)

            is SubmittedPage.Content.Image ->
                mapOf(
                    "type" to "image",
                    "attachment" to mapOf("url" to content.attachment.url),
                    "linkURL" to content.linkUrl,
                )

            is SubmittedPage.Content.ConfirmationText ->
                mapOf("type" to "confirmationText", "text" to content.text)

            is SubmittedPage.Content.Name -> mapOf("type" to "name")

            is SubmittedPage.Content.UserInput -> mapOf("type" to "userInput")

            is SubmittedPage.Content.UserInputScore -> mapOf("type" to "userInputScore")

            is SubmittedPage.Content.Link ->
                mapOf(
                    "type" to "link",
                    "text" to content.text,
                    "url" to content.url,
                )

            is SubmittedPage.Content.ReviewLinks ->
                mapOf(
                    "type" to "reviewLinks",
                    "links" to
                        content.links.map { link ->
                            mapOf(
                                "title" to link.title,
                                "url" to link.url,
                                "logo" to
                                    link.logo?.let {
                                        mapOf(
                                            "urlVector" to it.urlVector,
                                            "urlVectorDark" to it.urlVectorDark,
                                        )
                                    },
                                "icon" to
                                    link.icon?.let {
                                        mapOf(
                                            "urlRaster" to it.urlRaster,
                                            "urlRasterDark" to it.urlRasterDark,
                                        )
                                    },
                            )
                        },
                )
        }

    private fun encodeCondition(condition: SubmittedPage.Condition): Map<String, Any?> =
        when (condition) {
            is SubmittedPage.Condition.Score ->
                mapOf(
                    "type" to "score",
                    "ranges" to
                        condition.ranges.map { range ->
                            mapOf(
                                "lower" to range.lower,
                                "upper" to range.upper,
                            )
                        },
                )
        }

    private fun encodeTheme(theme: Theme): Map<String, Any?> =
        mapOf(
            "background" to encodeBackground(theme.background),
            "font" to encodeFont(theme.font),
            "cornerStyle" to
                when (theme.cornerStyle) {
                    Theme.CornerStyle.Rounded -> "rounded"
                    Theme.CornerStyle.Square -> "square"
                },
            "isBackgroundAttachmentVisibleInResponses" to
                theme.isBackgroundAttachmentVisibleInResponses,
            "isBackgroundColorVisibleInResponses" to
                theme.isBackgroundColorVisibleInResponses,
        )

    private fun encodeBackground(background: Theme.Background): Map<String, Any?> =
        when (background) {
            is Theme.Background.Predefined ->
                mapOf(
                    "type" to "predefined",
                    "value" to
                        when (background.value) {
                            Theme.Background.Predefined.Value.Plain -> "plain"
                            Theme.Background.Predefined.Value.Sponda -> "sponda"
                        },
                )

            is Theme.Background.Custom ->
                mapOf(
                    "type" to "custom",
                    "attachment" to
                        background.attachment?.let {
                            mapOf(
                                "id" to it.id,
                                "contentType" to it.contentType,
                                "url" to it.url,
                            )
                        },
                    "color" to mapOf("value" to background.color.value),
                )
        }

    private fun encodeFont(font: Theme.Font): Map<String, Any?> =
        when (font) {
            is Theme.Font.Predefined ->
                mapOf("type" to "predefined", "value" to font.value)

            is Theme.Font.Custom ->
                mapOf("type" to "custom", "url" to font.url)
        }

    private fun encodeContainer(container: Container): Map<String, Any?> =
        mapOf(
            "id" to container.id,
            "isWhiteLabel" to container.isWhiteLabel,
            "customLogos" to
                container.customLogos.map { logo ->
                    mapOf(
                        "size" to
                            when (logo.size) {
                                Container.CustomLogo.Size.Wide -> "wide"
                                Container.CustomLogo.Size.Square -> "square"
                            },
                        "intendedBackground" to
                            when (logo.intendedBackground) {
                                Container.CustomLogo.IntendedBackground.Light -> "light"
                                Container.CustomLogo.IntendedBackground.Dark -> "dark"
                            },
                        "primaryColor" to logo.primaryColor,
                        "urlVector" to logo.urlVector,
                    )
                },
            "visibilityMode" to
                when (container.visibilityMode) {
                    Container.VisibilityMode.Public -> "public"
                    Container.VisibilityMode.Private -> "private"
                },
        )

    private fun ScoreType.toApiValue(): String =
        when (this) {
            ScoreType.Smilies5 -> "smilies5"
            ScoreType.Smilies3 -> "smilies3"
            ScoreType.Thumbs -> "thumbs"
            ScoreType.Nps -> "nps"
            ScoreType.Stars5 -> "stars5"
        }
}
