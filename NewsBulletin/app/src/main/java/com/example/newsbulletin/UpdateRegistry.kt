package com.example.newsbulletin

interface ArticleUpdateListener {
    fun onArticleUpdate(message: String)
}

class UpdateRegistry {
    private val listeners = mutableSetOf<ArticleUpdateListener>()

    fun register(listener: ArticleUpdateListener) {
        listeners.add(listener)
    }

    fun unregister(listener: ArticleUpdateListener) {
        listeners.remove(listener)
    }

    fun listenerCount(): Int = listeners.size

    fun publish(message: String) {
        listeners.forEach { it.onArticleUpdate(message) }
    }
}
