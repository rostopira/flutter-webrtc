package org.webrtc;

import android.util.Log;

import java.util.Map;

public final class FixedHardwareVideoEncoder extends HardwareVideoEncoder {
    public FixedHardwareVideoEncoder(MediaCodecWrapperFactory mediaCodecWrapperFactory, String codecName, VideoCodecType codecType, Integer surfaceColorFormat, Integer yuvColorFormat, Map<String, String> params, int keyFrameIntervalSec, int forceKeyFrameIntervalMs, BitrateAdjuster bitrateAdjuster, EglBase14.Context sharedContext) {
        super(mediaCodecWrapperFactory, codecName, codecType, surfaceColorFormat, yuvColorFormat, params, keyFrameIntervalSec, forceKeyFrameIntervalMs, bitrateAdjuster, sharedContext);
    }
    @Override
    public VideoCodecStatus initEncode(Settings settings, Callback callback) {
        if (settings.height <= 900)
            return super.initEncode(settings, callback);
        final Settings fixedSettings = new Settings(
            settings.numberOfCores,
            settings.width,
            settings.height,
            1000,
            settings.maxFramerate,
            settings.numberOfSimulcastStreams,
            settings.automaticResizeOn
        );
        return super.initEncode(fixedSettings, callback);
    }
}
