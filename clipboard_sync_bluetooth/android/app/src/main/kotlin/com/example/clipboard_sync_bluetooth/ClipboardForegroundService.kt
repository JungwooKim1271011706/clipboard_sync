package com.example.clipboard_sync_bluetooth

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.app.PendingIntent
import android.content.Context

class ClipboardForegroundService : Service() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification: Notification = Notification.Builder(this, "CLIPBOARD_SERVICE_CHANNEL")
                .setContentTitle("Clipboard Sync")
                .setContentText("클립보드 감지 서비스 실행 중...")
                .setSmallIcon(R.drawable.ic_launcher)
                .setContentIntent(pendingIntent) // 사용자가 알림 클릭 시 앱 열기
                .addAction(Notification.Action.Builder(null, "종료", getStopServicePendingIntent()).build()) // ✅ 종료 버튼 추가
                .build()

        startForeground(1, notification) // ✅ Foreground Service 시작
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                    "CLIPBOARD_SERVICE_CHANNEL",
                    "Clipboard Sync Service",
                    NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun getStopServicePendingIntent(): PendingIntent {
        val stopIntent = Intent(this, ClipboardForegroundService::class.java)
        stopIntent.action = "STOP_SERVICE"
        return PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE)
    }
}
