package com.cloudwebrtc.webrtc.record;

import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import org.webrtc.VideoFrame;
import org.webrtc.VideoSink;
import org.webrtc.VideoTrack;
import org.webrtc.YuvHelper;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

import io.flutter.plugin.common.MethodChannel;

public class FrameCapturer implements VideoSink {
    private VideoTrack videoTrack;
    private File file;
    private final MethodChannel.Result callback;
    private boolean gotFrame = false;
    private final Context context;
    private final Integer rotation;

    public FrameCapturer(Context context, VideoTrack track, File file, MethodChannel.Result callback, Integer rotation) {
        videoTrack = track;
        this.file = file;
        this.callback = callback;
        this.context = context;
        if (rotation != null)
            this.rotation = rotation;
        else
            this.rotation = 0;
        track.addSink(this);
    }

    @Override
    public void onFrame(VideoFrame videoFrame) {
        if (gotFrame)
            return;
        gotFrame = true;
        videoFrame.retain();
        VideoFrame.Buffer buffer = videoFrame.getBuffer();
        VideoFrame.I420Buffer i420Buffer = buffer.toI420();
        ByteBuffer y = i420Buffer.getDataY();
        ByteBuffer u = i420Buffer.getDataU();
        ByteBuffer v = i420Buffer.getDataV();
        int width = i420Buffer.getWidth();
        int height = i420Buffer.getHeight();
        int[] strides = new int[] {
            i420Buffer.getStrideY(),
            i420Buffer.getStrideU(),
            i420Buffer.getStrideV()
        };
        int rotation = videoFrame.getRotation();
        final int chromaWidth = (width + 1) / 2;
        final int chromaHeight = (height + 1) / 2;
        final int minSize = width * height + chromaWidth * chromaHeight * 2;
        ByteBuffer yuvBuffer = ByteBuffer.allocateDirect(minSize);
        YuvHelper.I420ToNV12(y, strides[0], v, strides[2], u, strides[1], yuvBuffer, width, height);
        YuvImage yuvImage = new YuvImage(
            yuvBuffer.array(),
            ImageFormat.NV21,
            width,
            height,
            strides
        );
        videoFrame.release();
        new Handler(Looper.getMainLooper()).post(() -> videoTrack.removeSink(this));
        try {
            if (!file.exists())
                //noinspection ResultOfMethodCallIgnored
                file.createNewFile();
        } catch (IOException io) {
            callback.error("IOException", io.getLocalizedMessage(), null);
            return;
        }
        rotation += (this.rotation % 360);
        if (rotation == 0)
            try (FileOutputStream outputStream = new FileOutputStream(file)) {
                yuvImage.compressToJpeg(
                    new Rect(0, 0, width, height),
                    100,
                    outputStream
                );
                callback.success(null);
            } catch (IOException io) {
                callback.error("IOException", io.getLocalizedMessage(), io);
                return;
            } catch (IllegalArgumentException iae) {
                callback.error("IllegalArgumentException", iae.getLocalizedMessage(), null);
                return;
            }
        else {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            yuvImage.compressToJpeg(
                new Rect(0, 0, width, height),
                100,
                baos
            );
            byte[] jpeg = baos.toByteArray();
            Bitmap original = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.length);
            Matrix rotMat = new Matrix();
            rotMat.postRotate(rotation);
            Bitmap rotated = Bitmap.createBitmap(original, 0, 0, width, height, rotMat, true);
            baos.reset();
            rotated.compress(Bitmap.CompressFormat.JPEG, 100, baos);
            original.recycle();
            try (FileOutputStream outputStream = new FileOutputStream(file)) {
                baos.writeTo(outputStream);
            } catch (IOException io) {
                callback.error("IOException", io.getLocalizedMessage(), null);
                return;
            } catch (IllegalArgumentException iae) {
                callback.error("IllegalArgumentException", iae.getLocalizedMessage(), null);
                return;
            }
            callback.success(null);
        }
        if (!file.getAbsolutePath().contains("cache")) {
            // Display in default gallery app
            ContentValues values = new ContentValues(3);
            values.put(MediaStore.Images.Media.TITLE, file.getName());
            values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg");
            values.put(MediaStore.Images.Media.DATA, file.getAbsolutePath());
            context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
        }
    }

}