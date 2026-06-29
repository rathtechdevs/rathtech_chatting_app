package com.rathtech.securechat

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots and screen recording — required for a secure messaging app.
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
