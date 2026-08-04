package com.itDevStidio.BritishSchool;

import android.Manifest;
import android.app.Activity;
import android.app.DownloadManager;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Copies a finished download into the phone's public Downloads folder, so the
 * student can find the book with the system file browser and not just inside
 * the app. Android 10+ goes through MediaStore (no permission needed); older
 * versions write the file directly and need WRITE_EXTERNAL_STORAGE.
 */
public class DownloadsHandler implements MethodChannel.MethodCallHandler {

    static final String CHANNEL = "bsbschool/public_downloads";

    private static final int PERMISSION_REQUEST = 4711;

    private final Activity activity;
    private final ExecutorService io = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());

    /** Set while a pre-Android-10 write waits for the storage permission dialog. */
    private Runnable pendingWork;
    private MethodChannel.Result pendingResult;

    DownloadsHandler(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        final String fileName = call.argument("fileName");
        if (fileName == null || fileName.isEmpty()) {
            result.error("bad_arguments", "fileName is required", null);
            return;
        }

        final Runnable work;
        switch (call.method) {
            case "save":
                final String sourcePath = call.argument("sourcePath");
                final String mimeType = call.argument("mimeType");
                if (sourcePath == null) {
                    result.error("bad_arguments", "sourcePath is required", null);
                    return;
                }
                work = () -> runOnIo(
                        () -> save(new File(sourcePath), fileName,
                                mimeType == null ? "application/octet-stream" : mimeType),
                        result);
                break;
            case "delete":
                work = () -> runOnIo(() -> {
                    delete(fileName);
                    return null;
                }, result);
                break;
            default:
                result.notImplemented();
                return;
        }

        if (needsLegacyPermission()) {
            if (pendingResult != null) {
                result.error("busy", "Another storage request is already waiting", null);
                return;
            }
            pendingWork = work;
            pendingResult = result;
            activity.requestPermissions(
                    new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, PERMISSION_REQUEST);
            return;
        }
        work.run();
    }

    /** Resumes or fails the call that opened the storage permission dialog. */
    void onRequestPermissionsResult(int requestCode, int[] grantResults) {
        if (requestCode != PERMISSION_REQUEST || pendingResult == null) return;

        final Runnable work = pendingWork;
        final MethodChannel.Result result = pendingResult;
        pendingWork = null;
        pendingResult = null;

        if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            work.run();
        } else {
            result.error("permission_denied", "Yaddaşa yazmaq üçün icazə verilmədi", null);
        }
    }

    private boolean needsLegacyPermission() {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
                && activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED;
    }

    /** Runs [task] off the UI thread; the result is always delivered back on it. */
    private void runOnIo(IoTask task, MethodChannel.Result result) {
        io.execute(() -> {
            try {
                final Object value = task.run();
                main.post(() -> result.success(value));
            } catch (Exception e) {
                main.post(() -> result.error("io_error", String.valueOf(e.getMessage()), null));
            }
        });
    }

    private String save(File source, String fileName, String mimeType) throws IOException {
        if (!source.exists()) {
            throw new IOException("Yüklənmiş fayl tapılmadı: " + source.getPath());
        }
        // Replace an earlier copy of the same book instead of piling up
        // "book (1).pdf", "book (2).pdf" every time it is downloaded again.
        delete(fileName);
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                ? saveViaMediaStore(source, fileName, mimeType)
                : saveViaFileSystem(source, fileName, mimeType);
    }

    private String saveViaMediaStore(File source, String fileName, String mimeType)
            throws IOException {
        final ContentResolver resolver = activity.getContentResolver();

        final ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
        values.put(MediaStore.MediaColumns.MIME_TYPE, mimeType);
        values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);
        // Hidden from other apps until the bytes are all there.
        values.put(MediaStore.MediaColumns.IS_PENDING, 1);

        final Uri item = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
        if (item == null) throw new IOException("MediaStore faylı yaratmadı: " + fileName);

        try (InputStream in = new FileInputStream(source);
             OutputStream out = resolver.openOutputStream(item)) {
            if (out == null) throw new IOException("MediaStore faylı açmadı: " + fileName);
            copy(in, out);
        } catch (IOException | RuntimeException e) {
            resolver.delete(item, null, null);
            throw e;
        }

        final ContentValues published = new ContentValues();
        published.put(MediaStore.MediaColumns.IS_PENDING, 0);
        resolver.update(item, published, null, null);
        return item.toString();
    }

    @SuppressWarnings("deprecation")
    private String saveViaFileSystem(File source, String fileName, String mimeType)
            throws IOException {
        final File dir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IOException("Yükləmələr qovluğu yaradıla bilmədi");
        }
        final File target = new File(dir, fileName);
        try (InputStream in = new FileInputStream(source);
             OutputStream out = new FileOutputStream(target)) {
            copy(in, out);
        }
        // Lists the file in the system Downloads app; purely cosmetic, so a
        // device that refuses it still keeps the saved file.
        try {
            final DownloadManager manager =
                    (DownloadManager) activity.getSystemService(Context.DOWNLOAD_SERVICE);
            if (manager != null) {
                manager.addCompletedDownload(fileName, fileName, true, mimeType,
                        target.getAbsolutePath(), target.length(), true);
            }
        } catch (Exception ignored) {
            // Not fatal: the file is already in the Downloads folder.
        }
        return target.getAbsolutePath();
    }

    @SuppressWarnings("deprecation")
    private void delete(String fileName) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            final String selection = MediaStore.MediaColumns.RELATIVE_PATH + " LIKE ? AND "
                    + MediaStore.MediaColumns.DISPLAY_NAME + " = ?";
            final String[] args =
                    new String[]{Environment.DIRECTORY_DOWNLOADS + "/%", fileName};
            try {
                activity.getContentResolver()
                        .delete(MediaStore.Downloads.EXTERNAL_CONTENT_URI, selection, args);
            } catch (SecurityException ignored) {
                // Same name, but written by another app — leave it alone.
            }
            return;
        }
        final File target = new File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                fileName);
        if (target.exists()) target.delete();
    }

    private static void copy(InputStream in, OutputStream out) throws IOException {
        final byte[] buffer = new byte[8192];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        out.flush();
    }

    private interface IoTask {
        Object run() throws Exception;
    }
}
