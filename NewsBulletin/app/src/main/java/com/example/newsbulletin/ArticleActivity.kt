package com.example.newsbulletin

import android.app.Activity
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView

class ArticleActivity : Activity() {
    private val updateRegistry: UpdateRegistry
        get() = (application as NewsBulletinApplication).updateRegistry

    private var articleUpdateListener: ArticleUpdateListener? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_article)
        val articleIndex = intent.getIntExtra("article_index", 0).coerceIn(0, 2)
        val titles = intArrayOf(R.string.article_1_title, R.string.article_2_title, R.string.article_3_title)
        val bodies = intArrayOf(R.string.article_1_body, R.string.article_2_body, R.string.article_3_body)
        findViewById<TextView>(R.id.articleTitle).setText(titles[articleIndex])
        findViewById<TextView>(R.id.articleBody).setText(bodies[articleIndex])
        Log.d("LeakStudy", "screen=ArticleActivity event=onCreate articleIndex=$articleIndex listenerCount=${updateRegistry.listenerCount()}")

        findViewById<Button>(R.id.followUpdatesButton).setOnClickListener {
            Log.d("LeakStudy", "screen=ArticleActivity event=followClick articleIndex=$articleIndex")
            if (articleUpdateListener == null) {
                val listener = object : ArticleUpdateListener {
                    override fun onArticleUpdate(message: String) {
                        findViewById<TextView>(R.id.updateStatus).text = message
                        Log.d("LeakStudy", "screen=ArticleActivity event=updateDelivered articleIndex=$articleIndex")
                    }
                }
                articleUpdateListener = listener
                updateRegistry.register(listener)
                Log.d("LeakStudy", "screen=ArticleActivity event=listenerRegistered listenerCount=${updateRegistry.listenerCount()}")
            }
            updateRegistry.publish(getString(R.string.updates_active))
        }
    }

    override fun onDestroy() {
        if (articleUpdateListener != null) {
            // DEMO ONLY: Keep the listener in the application registry after this Activity is destroyed.
            Log.d("LeakStudy", "screen=ArticleActivity event=listenerIntentionallyRetained listenerCount=${updateRegistry.listenerCount()}")
        }
        Log.d("LeakStudy", "screen=ArticleActivity event=onDestroy listenerCount=${updateRegistry.listenerCount()}")
        super.onDestroy()
    }
}
