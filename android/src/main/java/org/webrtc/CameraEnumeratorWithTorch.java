package org.webrtc;

public final class CameraEnumeratorWithTorch extends Camera1Enumerator {

    private final boolean isCapturingToTexture;

    public CameraEnumeratorWithTorch(boolean captureToTexture) {
        super(captureToTexture);
        isCapturingToTexture = captureToTexture;
    }

    @Override
    public CameraVideoCapturer createCapturer(String deviceName, CameraVideoCapturer.CameraEventsHandler eventsHandler) {
        return new CameraCapturerWithTorch(deviceName, eventsHandler, isCapturingToTexture);
    }

}
