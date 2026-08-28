package io.qualtive.qualtive

import io.qualtive.Entry
import io.qualtive.Page
import io.qualtive.ScoreType

internal object EntryChannelMap {
    fun decode(raw: List<*>): List<Entry.Content> =
        raw.map { item ->
            val map =
                item as? Map<*, *>
                    ?: throw IllegalArgumentException("Invalid entry content item")
            decodeItem(map)
        }

    private fun decodeItem(map: Map<*, *>): Entry.Content {
        val type = map["type"] as? String
            ?: throw IllegalArgumentException("Missing entry content type")
        return when (type) {
            "title" ->
                Entry.Content.Title(
                    text = map["text"] as? String
                        ?: throw IllegalArgumentException("Missing title text"),
                )

            "score" ->
                Entry.Content.Score(
                    value = (map["value"] as? Number)?.toInt(),
                    definition = decodeScoreDefinition(map),
                )

            "text" ->
                Entry.Content.Text(
                    value = map["value"] as? String,
                    definition = decodeTextDefinition(map),
                )

            "select" ->
                Entry.Content.Select(value = map["value"] as? String)

            "multiselect" ->
                Entry.Content.Multiselect(values = stringList(map["values"]))

            "attachments" ->
                Entry.Content.Attachments(
                    attachments = decodeAttachmentReferences(map["values"]),
                )

            else -> throw IllegalArgumentException("Unknown entry content type: $type")
        }
    }

    private fun decodeScoreDefinition(map: Map<*, *>): Page.Content.Score? {
        val scoreTypeRaw = map["scoreType"] as? String ?: return null
        val scoreType =
            when (scoreTypeRaw) {
                "smilies5" -> ScoreType.Smilies5
                "smilies3" -> ScoreType.Smilies3
                "thumbs" -> ScoreType.Thumbs
                "nps" -> ScoreType.Nps
                "stars5" -> ScoreType.Stars5
                else -> throw IllegalArgumentException("Unknown scoreType: $scoreTypeRaw")
            }
        return Page.Content.Score(
            scoreType = scoreType,
            leadingText = map["leadingText"] as? String,
            trailingText = map["trailingText"] as? String,
        )
    }

    private fun decodeTextDefinition(map: Map<*, *>): Page.Content.Text? {
        val storage = map["storageTarget"] as? Map<*, *> ?: return null
        val targetType = storage["type"] as? String ?: return null
        val target =
            when (targetType) {
                "text" -> Page.Content.Text.StorageTarget.Text
                "attribute" ->
                    Page.Content.Text.StorageTarget.Attribute(
                        storage["attribute"] as? String
                            ?: throw IllegalArgumentException("Missing attribute name"),
                    )
                else -> throw IllegalArgumentException("Unknown storageTarget type: $targetType")
            }
        return Page.Content.Text(placeholder = null, storageTarget = target)
    }

    private fun decodeAttachmentReferences(raw: Any?): List<Entry.AttachmentReference> {
        val list = raw as? List<*> ?: return emptyList()
        return list.map { item ->
            val map =
                item as? Map<*, *>
                    ?: throw IllegalArgumentException("Invalid attachment reference")
            val id =
                (map["id"] as? Number)?.toLong()
                    ?: throw IllegalArgumentException("Missing attachment id")
            Entry.AttachmentReference(id = id)
        }
    }

    private fun stringList(raw: Any?): List<String> {
        val list = raw as? List<*> ?: return emptyList()
        return list.mapNotNull { it as? String }
    }
}
