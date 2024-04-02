package com.example.hello_example;

import androidx.annotation.NonNull;

import com.example.hello_example.CameraAndroid;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
      private static final String CHANNEL = "hello";

   @Override
   public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

       new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
               .setMethodCallHandler(
                       (call, result) -> {
                           if (call.method.equals("startRecording")) {
                               // Call your native method here
                                String dataPath=call.argument("path");
                            System.out.println("got data from flutter: "+dataPath);
                                CameraAndroid ca =new CameraAndroid(dataPath, this);
                                ca.capturePhoto();
                            String path=ca.getSavedVideoFilePath();
                                result.success("Video file Path:" + path);
                           } else {
                               result.notImplemented();
                           }
                       }
               );
   }
}
