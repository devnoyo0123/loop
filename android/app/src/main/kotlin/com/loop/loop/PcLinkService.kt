package com.loop.loop

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/// PC 연결 세션 유지 — 맥 브리지와 링크가 붙어 있는 동안만 도는 dataSync
/// 포그라운드 서비스. 화면이 꺼지거나 다른 앱을 써도 프로세스가 얼지 않아
/// Dart 소켓·재연결이 계속 돈다. 세션 길이(마지막 질의 후 30분)는 Dart
/// (PcLinkController)가 재고, 이 서비스는 알림과 수명만 맡는다. (ADR-003)
///
/// Dart로 가는 종료 사유([onEnded]):
///  - "user"    : 알림의 [연결 끊기]
///  - "timeout" : Android 15+ dataSync 하루 6시간 한도 소진(onTimeout)
///  - "denied"  : startForeground 거부 — Dart는 끊지 않고 기존 동작으로 폴백
class PcLinkService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_DISCONNECT) {
            end("user")
            return START_NOT_STICKY
        }
        try {
            ServiceCompat.startForeground(
                this,
                NOTIF_ID,
                buildNotification(),
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                } else {
                    0
                },
            )
        } catch (e: Exception) {
            // ForegroundServiceStartNotAllowedException 등 — 백그라운드 시작,
            // dataSync 한도 소진. 크래시 대신 세션 없이 계속.
            end("denied")
        }
        return START_NOT_STICKY
    }

    /// Android 15+ — dataSync 누적 6시간(24시간 기준) 초과. 몇 초 안에
    /// 멈추지 않으면 시스템이 ANR을 낸다.
    override fun onTimeout(startId: Int, fgsType: Int) {
        end("timeout")
    }

    /// Android 14 오버로드 (shortService 전용이지만 같은 처리로 둔다).
    override fun onTimeout(startId: Int) {
        end("timeout")
    }

    private fun end(reason: String) {
        onEnded?.invoke(reason)
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun buildNotification() =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_sync_noanim)
            .setContentTitle(getString(R.string.pclink_connected_title))
            .setContentText(getString(R.string.pclink_connected_text))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(openAppIntent())
            .addAction(0, getString(R.string.pclink_disconnect), disconnectIntent())
            .build()

    private fun openAppIntent(): PendingIntent? {
        val launch = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        return PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun disconnectIntent(): PendingIntent =
        PendingIntent.getService(
            this,
            1,
            Intent(this, PcLinkService::class.java).setAction(ACTION_DISCONNECT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    companion object {
        private const val ACTION_DISCONNECT = "com.loop.loop.PCLINK_DISCONNECT"
        private const val CHANNEL_ID = "loop_pc_link"
        private const val NOTIF_ID = 20261118

        /// 서비스 → Dart 종료 알림. MainActivity가 채널에 이어 둔다.
        /// 서비스 콜백은 메인 스레드라 바로 invokeMethod 해도 된다.
        @Volatile
        var onEnded: ((String) -> Unit)? = null

        private fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.pclink_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setSound(null, null) },
            )
        }

        /// 앱이 전경일 때만 부른다(연결·복귀 시). 시작 불가면 false —
        /// Dart는 세션 없이 기존 동작(배경에선 재연결 멈춤)으로 간다.
        fun start(context: Context): Boolean = try {
            ensureChannel(context)
            ContextCompat.startForegroundService(
                context,
                Intent(context, PcLinkService::class.java),
            )
            true
        } catch (e: Exception) {
            // Android 12+ ForegroundServiceStartNotAllowedException(IllegalStateException)
            false
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PcLinkService::class.java))
        }
    }
}
