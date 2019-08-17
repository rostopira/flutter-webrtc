package com.cloudwebrtc.webrtc.utils;

import android.util.Log;

import org.webrtc.Loggable;
import org.webrtc.Logging;

public final class MyLogger implements Loggable {
    @Override
    public void onLogMessage(String s, Logging.Severity severity, String s1) {
        if (s.equals("CameraCapturer")) {
            Log.wtf(s, s1);
        }
    }
}
