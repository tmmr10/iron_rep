package com.tmmr.iron_rep

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.graphics.BitmapFactory
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val BACKUP_CHANNEL = "com.tmmr.iron_rep/backup"
    private val NOTIFICATION_CHANNEL = "com.tmmr.iron_rep/notifications"
    private val PICK_FILE_REQUEST = 1001
    private val NOTIFICATION_PERMISSION_REQUEST = 1002
    private var pendingPickResult: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var backupChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null

    companion object {
        const val TIMER_CHANNEL_ID = "rest_timer"
        const val WORKOUT_CHANNEL_ID = "workout_ongoing"
        const val TIMER_NOTIFICATION_ID = 1
        const val WORKOUT_NOTIFICATION_ID = 2
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannels()

        // Backup channel
        backupChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
        backupChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickBackupFile" -> {
                    pendingPickResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    startActivityForResult(intent, PICK_FILE_REQUEST)
                }
                else -> result.notImplemented()
            }
        }

        // Notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestNotificationPermission(result)
                    "scheduleTimer" -> {
                        val args = call.arguments as? Map<*, *>
                        val seconds = args?.get("seconds") as? Int
                        val title = args?.get("title") as? String
                        val body = args?.get("body") as? String
                        if (seconds != null && title != null && body != null) {
                            scheduleTimer(seconds, title, body)
                            result.success(true)
                        } else {
                            result.error("BAD_ARGS", "Missing arguments", null)
                        }
                    }
                    "cancelTimer" -> {
                        cancelTimer()
                        result.success(true)
                    }
                    "showOngoingNotification" -> {
                        val args = call.arguments as? Map<*, *>
                        val title = args?.get("title") as? String
                        val body = args?.get("body") as? String
                        if (title != null && body != null) {
                            showOngoingNotification(title, body)
                            result.success(true)
                        } else {
                            result.error("BAD_ARGS", "Missing arguments", null)
                        }
                    }
                    "dismissOngoingNotification" -> {
                        dismissOngoingNotification()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Handle file opened via intent
        handleIncomingIntent(intent)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            val timerChannel = NotificationChannel(
                TIMER_CHANNEL_ID,
                "Pausentimer",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Benachrichtigung wenn der Pausentimer abgelaufen ist"
            }
            notificationManager.createNotificationChannel(timerChannel)

            val workoutChannel = NotificationChannel(
                WORKOUT_CHANNEL_ID,
                "Aktives Workout",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Zeigt an dass ein Workout läuft"
            }
            notificationManager.createNotificationChannel(workoutChannel)
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED
            ) {
                result.success(true)
            } else {
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST
                )
            }
        } else {
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun scheduleTimer(seconds: Int, title: String, body: String) {
        cancelTimer()

        timerRunnable = Runnable {
            showTimerNotification(title, body)
        }
        handler.postDelayed(timerRunnable!!, seconds * 1000L)
    }

    private fun cancelTimer() {
        timerRunnable?.let { handler.removeCallbacks(it) }
        timerRunnable = null
        NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
    }

    private fun launchIntent(route: String? = null): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (route != null) putExtra("route", route)
        }
        return PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun showTimerNotification(title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        val notification = NotificationCompat.Builder(this, TIMER_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setLargeIcon(largeIcon)
            .setColor(0xFF000000.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(launchIntent())
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()

        NotificationManagerCompat.from(this).notify(TIMER_NOTIFICATION_ID, notification)
    }

    private fun showOngoingNotification(title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val largeIcon = BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher)
        val notification = NotificationCompat.Builder(this, WORKOUT_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setLargeIcon(largeIcon)
            .setColor(0xFF000000.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(launchIntent("/active-workout"))
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        NotificationManagerCompat.from(this).notify(WORKOUT_NOTIFICATION_ID, notification)
    }

    private fun dismissOngoingNotification() {
        NotificationManagerCompat.from(this).cancel(WORKOUT_NOTIFICATION_ID)
    }

    // --- Backup file handling ---

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
        handleRouteIntent(intent)
    }

    private fun handleRouteIntent(intent: Intent?) {
        val route = intent?.getStringExtra("route") ?: return
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
            .invokeMethod("navigateTo", route)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (intent.action != Intent.ACTION_VIEW) return

        val path = copyUriToTempFile(uri) ?: return
        backupChannel?.invokeMethod("backupFileOpened", path)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PICK_FILE_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val path = copyUriToTempFile(data.data!!)
                if (path != null) {
                    pendingPickResult?.success(path)
                } else {
                    pendingPickResult?.error("COPY_ERROR", "Failed to copy file", null)
                }
            } else {
                pendingPickResult?.success(null)
            }
            pendingPickResult = null
        }
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "backup_import.ironrep")
            FileOutputStream(tempFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
