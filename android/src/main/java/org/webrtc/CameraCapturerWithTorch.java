package org.webrtc;

import android.content.Context;
import android.hardware.Camera;
import android.os.Handler;
import android.os.Looper;

import java.lang.reflect.Field;

public final class CameraCapturerWithTorch extends Camera1Capturer implements CameraSession.CreateSessionCallback {
    private final boolean isCapturingToTexture;
    private MyCameraSession cameraSession;
    private CameraSession.CreateSessionCallback createSessionCallback;

    public CameraCapturerWithTorch(String cameraName, CameraEventsHandler eventsHandler, boolean captureToTexture) {
        super(cameraName, eventsHandler, captureToTexture);
        isCapturingToTexture = captureToTexture;
    }

    @Override
    protected void createCameraSession(CameraSession.CreateSessionCallback createSessionCallback, CameraSession.Events events, Context applicationContext, SurfaceTextureHelper surfaceTextureHelper, String cameraName, int width, int height, int framerate) {
        this.createSessionCallback = createSessionCallback;
        MyCameraSession.create(this, events, isCapturingToTexture, applicationContext, surfaceTextureHelper, Camera1Enumerator.getCameraIndex(cameraName), width, height, framerate);
    }

    @Override
    public void onDone(CameraSession cameraSession) {
        this.cameraSession = (MyCameraSession) cameraSession;
        if (createSessionCallback != null) {
            createSessionCallback.onDone(cameraSession);
            createSessionCallback = null;
        }
    }

    @Override
    public void onFailure(CameraSession.FailureType failureType, String s) {
        if (createSessionCallback != null) {
            createSessionCallback.onFailure(failureType, s);
            createSessionCallback = null;
        }
    }

    public void setTorch(boolean enabled) throws Exception {
//        // Private? Really? Oh for fucks sake...
//        Field f = cameraSession.getClass().getDeclaredField("camera");
//        // Hello, poorly designed class
//        f.setAccessible(true);
//        // Give it to me plz
//        Camera camera = (Camera) f.get(cameraSession);
//        // Thank you, piece of shit
        Camera camera = cameraSession.camera;
        final Camera.Parameters parameters = camera.getParameters();
        parameters.setFlashMode(enabled ? Camera.Parameters.FLASH_MODE_TORCH : Camera.Parameters.FLASH_MODE_OFF);
        camera.setParameters(parameters);
    }
}
