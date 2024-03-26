package com.example.sender_app




import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/my_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    print("this is method $call.method")
                    if (call.method == "nativeMethodName") {
                        // Call your native method here
                        val nativeResult = nativeMethodImplementation()
                        result.success(nativeResult)
                    } else {
                        result.notImplemented()
                    }
                }
    }

    private fun nativeMethodImplementation(): String {
        // Implement your native method logic
        return "Native method result"
    }
}
