package com.example.newsbulletin

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Button

class HomeActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)
        Log.d("LeakStudy", "screen=HomeActivity event=onCreate")

        val articleButtons = listOf(
            R.id.firstArticleButton,
            R.id.secondArticleButton,
            R.id.thirdArticleButton
        )
        articleButtons.forEachIndexed { index, buttonId ->
            findViewById<Button>(buttonId).setOnClickListener {
                Log.d("LeakStudy", "screen=HomeActivity event=openArticle articleIndex=$index")
                startActivity(Intent(this, ArticleActivity::class.java).putExtra("article_index", index))
            }
        }
        findViewById<Button>(R.id.aboutButton).setOnClickListener {
            Log.d("LeakStudy", "screen=HomeActivity event=openAbout")
            startActivity(Intent(this, AboutActivity::class.java))
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d("LeakStudy", "screen=HomeActivity event=onResume")
    }

    override fun onDestroy() {
        Log.d("LeakStudy", "screen=HomeActivity event=onDestroy")
        super.onDestroy()
    }
}
