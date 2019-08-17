package com.cloudwebrtc.webrtc.codecs;

import android.util.Log;

import androidx.annotation.Nullable;

import org.webrtc.DefaultVideoDecoderFactory;
import org.webrtc.EglBase;
import org.webrtc.VideoCodecInfo;
import org.webrtc.VideoDecoder;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class VideoDecoderFactory extends DefaultVideoDecoderFactory {
    private List<String> priorities;

    public VideoDecoderFactory(EglBase.Context eglContext) {
        super(eglContext);
        priorities = Arrays.asList("H264", "VP8", "VP9");
    }

    @Override
    public VideoCodecInfo[] getSupportedCodecs() {
        final List<VideoCodecInfo> supported = new ArrayList<>(Arrays.asList(super.getSupportedCodecs()));
        final VideoCodecInfo[] sorted = new VideoCodecInfo[supported.size()];
        int i = 0;
        for (String codec : priorities) {
            int j = 0;
            while (j < supported.size() && !codec.equals(supported.get(j).name))
                j++;
            if (j < supported.size()) {
                sorted[i++] = supported.get(j);
                supported.remove(j);
            }
        }
        while (i < sorted.length && !supported.isEmpty()) {
            final VideoCodecInfo codecInfo = supported.get(0);
            supported.remove(0);
            sorted[i++] = codecInfo;
        }
        return sorted;
    }

}