package org.webrtc;

import android.util.Log;

import androidx.annotation.Nullable;

import org.webrtc.DefaultVideoEncoderFactory;
import org.webrtc.EglBase;
import org.webrtc.FixedHardwareVideoEncoderFactory;
import org.webrtc.VideoCodecInfo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class FixedVideoEncoderFactory extends DefaultVideoEncoderFactory {

    public FixedVideoEncoderFactory(EglBase.Context eglContext, boolean disableVp8) {
        super(new FixedHardwareVideoEncoderFactory(eglContext, false, true));
    }

    @Override
    public VideoCodecInfo[] getSupportedCodecs() {
        final List<VideoCodecInfo> supported = new ArrayList<>(Arrays.asList(super.getSupportedCodecs()));
        final List<VideoCodecInfo> h264 = new ArrayList<>();
        for (VideoCodecInfo info : supported) {
            if (info.name.equals("H264"))
                h264.add(info);
        }
        if (!h264.isEmpty())
            return h264.toArray(new VideoCodecInfo[0]);
        return super.getSupportedCodecs();
//        final List<VideoCodecInfo> supported = new ArrayList<>(Arrays.asList(super.getSupportedCodecs()));
//        final List<VideoCodecInfo> sorted = new ArrayList<>();
//        boolean hasH264 = false;
//        for (VideoCodecInfo codec : supported) {
//            if (codec.name.equals("H264"))
//                hasH264 = true;
//            sorted.add(codec);
//            supported.remove(codec);
//            break;
//        }
//        while (!supported.isEmpty()) {
//            final VideoCodecInfo codecInfo = supported.get(0);
//            supported.remove(0);
//            if (codecInfo.name.equals("VP8")) {
//                if (!hasH264)
//                    sorted.add(0, codecInfo);
//            } else {
//                sorted.add(codecInfo);
//            }
//        }
//        for (VideoCodecInfo info : sorted) {
//            Log.wtf("WTF", info.name);
//        }
//        return sorted.toArray(new VideoCodecInfo[0]);
    }

    @Override
    public VideoEncoder createEncoder(VideoCodecInfo info) {
        final VideoEncoder encoder = super.createEncoder(info);
        Log.wtf("WTF", "IS HARDWARE ENCODER" + encoder.isHardwareEncoder());
        return encoder;
    }
}