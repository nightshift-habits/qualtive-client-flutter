package io.qualtive.qualtive

import io.qualtive.Entry
import io.qualtive.Page
import io.qualtive.ScoreType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EntryChannelMapTest {
    @Test
    fun decodeMapsAllContentTypes() {
        val content =
            EntryChannelMap.decode(
                listOf(
                    mapOf("type" to "title", "text" to "Hello"),
                    mapOf(
                        "type" to "score",
                        "value" to 75,
                        "scoreType" to "stars5",
                        "leadingText" to "Bad",
                        "trailingText" to "Good",
                    ),
                    mapOf(
                        "type" to "text",
                        "value" to "Hi",
                        "storageTarget" to
                            mapOf(
                                "type" to "attribute",
                                "attribute" to "Age",
                            ),
                    ),
                    mapOf("type" to "select", "value" to "A"),
                    mapOf("type" to "multiselect", "values" to listOf("X", "Y")),
                    mapOf(
                        "type" to "attachments",
                        "values" to listOf(mapOf("id" to 99L)),
                    ),
                ),
            )

        assertEquals(6, content.size)

        val title = content[0] as Entry.Content.Title
        assertEquals("Hello", title.text)

        val score = content[1] as Entry.Content.Score
        assertEquals(75, score.value)
        assertEquals(ScoreType.Stars5, score.definition?.scoreType)
        assertEquals("Bad", score.definition?.leadingText)
        assertEquals("Good", score.definition?.trailingText)

        val text = content[2] as Entry.Content.Text
        assertEquals("Hi", text.value)
        val target = text.definition?.storageTarget as Page.Content.Text.StorageTarget.Attribute
        assertEquals("Age", target.attribute)

        val select = content[3] as Entry.Content.Select
        assertEquals("A", select.value)

        val multi = content[4] as Entry.Content.Multiselect
        assertEquals(listOf("X", "Y"), multi.values)

        val attachments = content[5] as Entry.Content.Attachments
        assertEquals(99L, attachments.attachments[0].id)
    }

    @Test
    fun decodeOmitsScoreDefinitionWhenScoreTypeMissing() {
        val content =
            EntryChannelMap.decode(
                listOf(
                    mapOf("type" to "score", "value" to 50),
                    mapOf("type" to "text", "value" to "Hello"),
                    mapOf("type" to "attachments", "values" to emptyList<Any>()),
                ),
            )

        val score = content[0] as Entry.Content.Score
        assertEquals(50, score.value)
        assertNull(score.definition)

        val text = content[1] as Entry.Content.Text
        assertEquals("Hello", text.value)
        assertNull(text.definition)

        val attachments = content[2] as Entry.Content.Attachments
        assertTrue(attachments.attachments.isEmpty())
    }
}
