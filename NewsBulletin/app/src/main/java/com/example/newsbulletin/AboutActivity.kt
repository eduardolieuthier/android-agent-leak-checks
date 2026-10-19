package com.example.newsbulletin

import android.app.Activity
import android.os.Bundle
import android.util.Log

class AboutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_about)
        Log.d("LeakStudy", "screen=AboutActivity event=onCreate")
    }

    override fun onDestroy() {
        Log.d("LeakStudy", "screen=AboutActivity event=onDestroy")
        super.onDestroy()
    }
}
