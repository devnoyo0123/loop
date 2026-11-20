package com.loop.loop

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/// 알람 발화 수신 — **전체화면 인텐트 알림** 게시 + **벨소리 서비스** 시작.
/// Android 10+의 백그라운드 화면 실행 제한(One UI 강화 포함)에 걸리지 않는
/// 시계 앱 정석 경로. (2026-10-30 실기기 보고 수정)
///
/// - 화면 꺼짐/잠금: 시스템이 fullScreenIntent(AlarmActivity)를 전체화면으로 띄움
/// - 사용 중: 소리·버튼이 있는 헤드업 배너
/// - 알람음: AlarmSoundService가 STREAM_ALARM으로 직접 재생(확인까지 반복) —
///   알림 채널 소리는 One UI가 FSI 발화 때 스킵하고 DND에도 묵살되므로 사용하지
///   않는다. (2026-11-01)
///
/// 재전달 방지: 절전 중 시스템이 같은 방송을 다시 보내면 같은 예약 시각
/// (atMs)으로 걸러낸다. (2026-10-24 알람 3중 울림 버그 수정분 계승)
class AlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        ensureChannel(context)
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> NativeAlarms.rescheduleFromPrefs(context)
            ACTION_SNOOZE -> snooze(context, intent)
            ACTION_CONFIRM -> dismiss(context, intent)
            else -> fire(context, intent)
        }
    }

    private fun fire(context: Context, intent: Intent) {
        val logId = intent.getStringExtra(EXTRA_LOG_ID) ?: return
        val atMs = intent.getLongExtra(EXTRA_AT_MS, -1L)
        val content = intent.getStringExtra(EXTRA_CONTENT) ?: ""

        // 절전 중 시스템이 같은 방송을 재전달하면 같은 예약 시각이 온다 — 무시.
        if (NativeAlarms.isRedelivery(context, logId, atMs)) return
        NativeAlarms.markFired(context, logId, atMs)
        NativeAlarms.cancel(context, logId)

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        // 화면이 켜져 있고 오버레이 권한이 있으면 서비스의 오버레이가 알람 UI를
        // 대신 보여주므로 알림(헤드업 배너)을 건너뛴다 — 알람 모드에서 배너가
        // 한 번 떴다 사라지는 이중 표시를 막는다. 화면이 꺼졌을 때는 FSI 알림이
        // AlarmActivity를 띄워야 하므로 이때만 게시한다. (2026-11-01)
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val plan = AlarmPresentation.plan(
            sdkInt = Build.VERSION.SDK_INT,
            screenOn = power.isInteractive,
            overlayAllowed = Settings.canDrawOverlays(context),
            fullScreenAllowed = if (Build.VERSION.SDK_INT >= AlarmPresentation.FSI_PERMISSION_SDK) {
                nm.canUseFullScreenIntent()
            } else {
                true
            },
        )
        if (plan.postNotification) {
            nm.notify(logId.hashCode(), buildNotification(context, logId, content, plan))
        }

        // 소리·진동은 서비스가 직접 내고, 화면이 켜져 있으면 서비스의
        // 오버레이가 알람 UI를 어떤 앱 위로든 띄운다. 화면이 꺼졌을 때는
        // 위 FSI 알림이 AlarmActivity를 전체화면으로 띄운다. (2026-11-01)
        AlarmSoundService.start(context, logId, content)
    }

    private fun snooze(context: Context, intent: Intent) {
        val logId = intent.getStringExtra(EXTRA_LOG_ID) ?: return
        val content = intent.getStringExtra(EXTRA_CONTENT) ?: ""
        val at = System.currentTimeMillis() + SNOOZE_MS
        NativeAlarms.schedule(context, logId, at, content)
        NativeAlarms.markSnoozed(context, logId, at)
        AlarmSoundService.stop(context)
        cancelNotification(context, logId)
    }

    private fun dismiss(context: Context, intent: Intent) {
        val logId = intent.getStringExtra(EXTRA_LOG_ID) ?: return
        NativeAlarms.cancel(context, logId)
        AlarmSoundService.stop(context)
        cancelNotification(context, logId)
    }

    fun cancelNotification(context: Context, logId: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        nm.cancel(logId.hashCode())
    }

    private fun buildNotification(
        context: Context,
        logId: String,
        content: String,
        plan: AlarmPresentation.Plan,
    ): Notification {
        val activity = PendingIntent.getActivity(
            context, logId.hashCode(),
            Intent(context, AlarmActivity::class.java)
                .putExtra(NativeAlarms.EXTRA_LOG_ID, logId)
                .putExtra(NativeAlarms.EXTRA_CONTENT, content),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val snooze = PendingIntent.getBroadcast(
            context, logId.hashCode(),
            Intent(context, AlarmReceiver::class.java)
                .setAction(ACTION_SNOOZE)
                .putExtra(EXTRA_LOG_ID, logId)
                .putExtra(EXTRA_CONTENT, content),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val confirm = PendingIntent.getBroadcast(
            context, logId.hashCode() + 1,
            Intent(context, AlarmReceiver::class.java)
                .setAction(ACTION_CONFIRM)
                .putExtra(EXTRA_LOG_ID, logId),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // 알림칸에서 스와이프로 지워도 벨소리가 멈추도록 — 지우기 = 확인 취급.
        val delete = confirm

        val ko = context.resources.configuration.locales[0].language == "ko"
        val snoozeText =
            if (ko) "10분 후 다시" else context.getString(R.string.alarm_snooze)
        val confirmText =
            if (ko) context.getString(R.string.alarm_confirm) else context.getString(R.string.alarm_confirm)

        val style = android.app.Notification.BigTextStyle()
            .bigText(content.ifBlank {
                if (ko) "(내용 없음)" else context.getString(R.string.alarm_no_content)
            })

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            android.app.Notification.Builder(context)
        }
        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("↩ Loop")
            .setContentText(content.ifBlank { "" })
            .setStyle(style)
            .setCategory(Notification.CATEGORY_ALARM)
            .setPriority(android.app.Notification.PRIORITY_MAX)
            .setFullScreenIntent(activity, true)
            .addAction(0, snoozeText, snooze)
            .addAction(0, confirmText, confirm)
            .setDeleteIntent(delete)
            .setAutoCancel(false)
        // 탭하면 알람 화면 — FSI가 막혀 일반 알림으로 왔을 때 바로 찾아간다.
        if (plan.tapOpensAlarm) builder.setContentIntent(activity)
        // 전체 화면 알림이 막혀 있다 — 원인을 알려주고 한 번에 켜러 간다.
        if (plan.offerEnableFullScreen && Build.VERSION.SDK_INT >= AlarmPresentation.FSI_PERMISSION_SDK) {
            val settings = PendingIntent.getActivity(
                context, logId.hashCode() + 2,
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    android.net.Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.addAction(0, context.getString(R.string.alarm_enable_fullscreen), settings)
            builder.setSubText(context.getString(R.string.alarm_fullscreen_off))
        }
        return builder.build()
    }

    /// 알람 알림 채널 — 소리·진동은 AlarmSoundService가 직접 내므로 채널은
    /// 무음(HEADS_UP 표시용 HIGH만 유지). 구버전(알람음 채널)은 제거.
    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager
        nm.deleteNotificationChannel("loop_alarm_fires")
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                if (context.resources.configuration.locales[0].language == "ko") "루프 알람"
                else "Loop alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { setSound(null, null) },
        )
        AlarmSoundService.ensureServiceChannel(context)
    }

    companion object {
        const val ACTION_FIRE = "com.loop.loop.ALARM_FIRE"
        const val ACTION_SNOOZE = "com.loop.loop.ALARM_SNOOZE"
        const val ACTION_CONFIRM = "com.loop.loop.ALARM_CONFIRM"
        const val EXTRA_LOG_ID = "logId"
        const val EXTRA_CONTENT = "content"
        const val EXTRA_AT_MS = "atMs"

        /// v2 — 소리 없는 알림 채널. 실제 벨소리는 AlarmSoundService가
        /// STREAM_ALARM으로 재생(2026-11-01 One UI FSI 무음 문제 수정).
        const val CHANNEL_ID = "loop_alarm_fires_v2"
        private const val SNOOZE_MS = 10L * 60 * 1000
    }
}
