package com.kasem.receive_sharing_intent

public data class Message(val text: String?, val subject: String?) {


    public fun asHashMap(): java.util.HashMap<String, String?> {

        return hashMapOf(
                "text" to text,
                "subject" to subject
        )
    }
}