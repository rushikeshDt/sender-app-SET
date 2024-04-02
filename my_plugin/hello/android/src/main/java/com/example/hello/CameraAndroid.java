package com.example.hello;

import android.content.Context;



import android.media.CamcorderProfile;
import android.media.MediaRecorder;
import android.os.Environment;

import androidx.camera.core.Camera;
import androidx.camera.lifecycle.ProcessCameraProvider;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.Executor;

public class CameraAndroid {
    private MediaRecorder recorder;
    private boolean recording = false;

private String dataPath;
private String filePath;
private Camera camera;
private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;
    Context ctx;
    public CameraAndroid(String path, Context ct) {
        ctx=ct;
dataPath=path;
filePath=dataPath+"/videocapture_example.mp4";
        System.out.println("[CameraAndroid] Starting");
        System.out.println("[CameraAndroid] storageDir:"+dataPath);
        // Check if permission is granted


        recorder = new MediaRecorder();
        recorder.setOnInfoListener((mediaRecorder, what, i1) -> {
            System.out.println("[CameraAndroid] event occured and code:"+what);
            if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) {
                // Stop recording or take necessary actions
                stopRecording();
            }

        });
        cameraProviderFuture = ProcessCameraProvider.getInstance(ctx);
        cameraProviderFuture.addListener(() -> {
            try {
                ProcessCameraProvider cameraProvider = cameraProviderFuture.get();

            } catch (Exception e) {
                e.printStackTrace();
            }
        }, getMainExecutor());
        initRecorder();
    }

    private Executor getMainExecutor() {
        return ctx.getMainExecutor();
    }
    private void startCameraX(ProcessCameraProvider processCameraProvider){
        processCameraProvider.unbindAll();
    }

    private void initRecorder() {
        System.out.println("Starting init");

        recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        recorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);

        recorder.setOutputFile(filePath);
        CamcorderProfile cp480 = CamcorderProfile.get(CamcorderProfile.QUALITY_LOW);
        recorder.setProfile(cp480);
        recorder.setVideoFrameRate(30);
       // Specify your desired file path
        recorder.setMaxDuration(50000); // 50 seconds
        recorder.setMaxFileSize(5000000);

       // Approximately 5 megabytes
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
