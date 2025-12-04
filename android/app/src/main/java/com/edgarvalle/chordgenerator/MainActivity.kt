package com.edgarvalle.chordgenerator

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.edgarvalle.chordgenerator.databinding.ActivityMainBinding

/**
 * Groovy Chord Generator
 * Main Activity with WebView for displaying the chord generator app
 * 
 * @author Edgar Valle
 * @version 2.5.0
 */
class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        webView = binding.webView
        setupWebView()
        setupBackPressHandler()
        
        // Load the local HTML file from assets
        webView.loadUrl("file:///android_asset/index.html")
    }

    private fun setupWebView() {
        webView.settings.apply {
            // JavaScript is required for the React app to function.
            // This is safe because we only load local content from assets,
            // not from the internet, eliminating XSS risks.
            javaScriptEnabled = true
            
            // Enable DOM storage for localStorage support
            domStorageEnabled = true
            
            // Allow file access for loading local assets
            allowFileAccess = true
            
            // Configure viewport settings
            loadWithOverviewMode = true
            useWideViewPort = true
            
            // Disable zoom controls for app-like experience
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            
            // Enable media playback without user gesture (for audio)
            mediaPlaybackRequiresUserGesture = false
            
            // Enable database storage
            databaseEnabled = true
        }
        
        // Set WebViewClient to handle navigation within the app
        webView.webViewClient = WebViewClient()
    }

    private fun setupBackPressHandler() {
        // Use the modern OnBackPressedCallback for Android 13+ compatibility
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (webView.canGoBack()) {
                    webView.goBack()
                } else {
                    // Disable this callback and trigger the default back behavior
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                }
            }
        })
    }
    
    override fun onPause() {
        super.onPause()
        webView.onPause()
    }
    
    override fun onResume() {
        super.onResume()
        webView.onResume()
    }
    
    override fun onDestroy() {
        webView.destroy()
        super.onDestroy()
    }
}
