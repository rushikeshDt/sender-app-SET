 import androidx.annotation.NonNull;

 import io.flutter.embedding.android.FlutterActivity;
 import io.flutter.embedding.engine.FlutterEngine;
 import io.flutter.plugin.common.MethodChannel;

 public class MainActivity extends FlutterActivity {
   private static final String CHANNEL = "com.example/my_channel";

   @Override
   public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {

       new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
               .setMethodCallHandler(
                       (call, result) -> {
                           if (call.method.equals("nativeMethodName")) {
                               // Call your native method here
                               String nativeResult = nativeMethodImplementation();
                               result.success(nativeResult);
                           } else {
                               result.notImplemented();
                           }
                       }
               );
   }

   private String nativeMethodImplementation() {
     // Implement your native method logic
     return "Native method result";
   }
 }
