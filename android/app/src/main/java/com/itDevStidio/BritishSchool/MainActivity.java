package com.itDevStidio.BritishSchool;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {

    /** Serves the Dart side's requests to write books into public Downloads. */
    private DownloadsHandler downloads;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        downloads = new DownloadsHandler(this);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),
                DownloadsHandler.CHANNEL)
                .setMethodCallHandler(downloads);
    }

    @Override
    public void onRequestPermissionsResult(
            int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (downloads != null) downloads.onRequestPermissionsResult(requestCode, grantResults);
    }
}
