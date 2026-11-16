package com.adesse.app;

import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            WebView webView = getBridge().getWebView();
            if (webView != null) {
                webView.setOverScrollMode(WebView.OVER_SCROLL_NEVER);
                WebSettings settings = webView.getSettings();
                String ua = settings.getUserAgentString();
                if (ua != null) {
                    // Normalize User Agent by removing WebView tokens (; wv and Version/X.X)
                    // so Google OAuth and OAuth providers allow standard web authentication flow
                    String cleanUa = ua.replaceAll("(?i);\\s*wv", "").replaceAll("(?i)Version/\\d+\\.\\d+\\s*", "");
                    settings.setUserAgentString(cleanUa);
                }
            }
        } catch (Exception e) {
            // Fallback gracefully if webview is unavailable during init
        }
    }
}
