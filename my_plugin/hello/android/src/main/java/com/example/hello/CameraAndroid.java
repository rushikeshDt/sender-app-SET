package com.example.hello;

import android.media.CamcorderProfile;
import android.media.MediaRecorder;
import android.os.Environment;

public class CameraAndroid {
    private MediaRecorder recorder;
    private boolean recording = false;
    private String storageDir= Environment.getExternalStorageDirectory().getPath();
private String filePath=storageDir+"/videocapture_example.mp4";
    public CameraAndroid() {
        System.out.println("[CameraAndroid] Starting");
        // Check if permission is granted


        recorder = new MediaRecorder();
        recorder.setOnInfoListener((mediaRecorder, what, i1) -> {
            System.out.println("[CameraAndroid] event occured and code:"+what);
            if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) {
                // Stop recording or take necessary actions
                stopRecording();
            }

        });
        initRecorder();
    }

    private void initRecorder() {
        recorder.setAudioSource(MediaRecorder.AudioSource.DEFAULT);
        recorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);

        CamcorderProfile cp480 = CamcorderProfile.get(CamcorderProfile.QUALITY_LOW);
        recorder.setProfile(cp480);
System.out.println("[CameraAndroid] storageDir:"+storageDir);
        recorder.setOutputFile(filePath); // Specify your desired file path
        recorder.setMaxDuration(50000); // 50 seconds
        recorder.setMaxFileSize(5000000); // Approximately 5 megabytes
    }

    public void startRecording() {
        if (!recording) {
            try {
                recorder.prepare();
                recorder.start();
                recording = true;
            }catch (Exception e){
                System.out.println("[CameraAndroid.startRecording] caught exception "+e.toString());
            }

        }
    }

    public void stopRecording() {
        System.out.println("Stopping recording");
        if (recording) {
            recorder.stop();
            recorder.reset();
            initRecorder(); // Reinitialize the recorder for subsequent recordings
            recording = false;

        }
    }

    // Getter method for the saved video file path
    public String getSavedVideoFilePath() {
        return filePath; // Replace with the actual path
    }
}
