package io.qualtive.qualtive

import io.qualtive.Attachment
import io.qualtive.Container
import io.qualtive.Enquiry
import io.qualtive.Page
import io.qualtive.ScoreType
import io.qualtive.SubmittedPage
import io.qualtive.Theme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class EnquiryChannelMapTest {
    @Test
    fun encodeMapsPublicEnquiryFields() {
        val map = EnquiryChannelMap.encode(sampleEnquiry())

        assertEquals(1L, map["id"])
        assertEquals("flutter", map["slug"])
        assertEquals("Flutter", map["name"])
        assertEquals(false, map["isUserContactDetailsRequired"])

        @Suppress("UNCHECKED_CAST")
        val pages = map["pages"] as List<Map<String, Any?>>
        @Suppress("UNCHECKED_CAST")
        val content = pages[0]["content"] as List<Map<String, Any?>>
        assertEquals("title", content[0]["type"])
        assertEquals("Hello", content[0]["text"])
        assertEquals("score", content[1]["type"])
        assertEquals("stars5", content[1]["scoreType"])
        assertEquals("Bad", content[1]["leadingText"])
        assertEquals("Good", content[1]["trailingText"])
        assertEquals("attachments", content[2]["type"])

        @Suppress("UNCHECKED_CAST")
        val theme = map["theme"] as Map<String, Any?>
        assertEquals("rounded", theme["cornerStyle"])
        @Suppress("UNCHECKED_CAST")
        val background = theme["background"] as Map<String, Any?>
        assertEquals("predefined", background["type"])
        assertEquals("plain", background["value"])

        @Suppress("UNCHECKED_CAST")
        val container = map["container"] as Map<String, Any?>
        assertEquals("ci-test", container["id"])
        assertEquals("private", container["visibilityMode"])

        @Suppress("UNCHECKED_CAST")
        val submitted = map["submittedPages"] as List<Map<String, Any?>>
        @Suppress("UNCHECKED_CAST")
        val submittedContent = submitted[0]["content"] as List<Map<String, Any?>>
        assertEquals("confirmationText", submittedContent[0]["type"])
        assertNull(submittedContent[1]["linkURL"])
    }

    private fun sampleEnquiry(): Enquiry =
        Enquiry(
            id = 1L,
            slug = "flutter",
            name = "Flutter",
            pages =
            listOf(
                Page(
                    content =
                    listOf(
                        Page.Content.Title("Hello"),
                        Page.Content.Score(
                            scoreType = ScoreType.Stars5,
                            leadingText = "Bad",
                            trailingText = "Good",
                        ),
                        Page.Content.Attachments,
                    ),
                ),
            ),
            submittedPages =
            listOf(
                SubmittedPage(
                    content =
                    listOf(
                        SubmittedPage.Content.ConfirmationText("Thanks"),
                        SubmittedPage.Content.Image(
                            attachment = Attachment(url = "https://example.com/a.png"),
                            linkUrl = null,
                        ),
                    ),
                    conditions = emptyList(),
                ),
            ),
            theme =
            Theme(
                background =
                Theme.Background.Predefined(
                    Theme.Background.Predefined.Value.Plain,
                ),
                font = Theme.Font.Predefined("default"),
                cornerStyle = Theme.CornerStyle.Rounded,
                isBackgroundAttachmentVisibleInResponses = true,
                isBackgroundColorVisibleInResponses = true,
            ),
            container =
            Container(
                id = "ci-test",
                isWhiteLabel = false,
                logo = null,
                customLogos = emptyList(),
                version = "qualtive",
                visibilityMode = Container.VisibilityMode.Private,
            ),
            isUserContactDetailsRequired = false,
        )
}
