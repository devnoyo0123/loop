package com.loop.loop

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button

/// 알람 벨소리 재생 전용 포그라운드 서비스 — 시계 앱과 같은 구조.
///
/// One UI는 FSI로 액티비티를 띄울 때 알림 채널 사운드 재생을 스킵한다
/// (2026-11-01 실측: INSISTENT 알림이 활성인데 audio_flinger 활성 트랙 0개,
/// Ringtone 생성 로그 없음). 알림 소리에 의존하면 방해 금지·OEM 동작에 따라
/// 묵살되므로, 앱이 직접 알람 스트림(STREAM_ALARM)으로 재생한다. 알람 볼륨이
/// 0이면 최소 가청 볼륨으로 올려서라도 울린다 — "꺼야 멈춤, 무음에도"가
/// 알람 모드의 약속. (2026-11-01)
class AlarmSoundService : Service() {

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var focusRequest: AudioFocusRequest? = null
    private var overlayView: View? = null
    private var ringLogId: String = ""
    private var ringContent: String = ""

    /// 화면이 켜져 있는 동안 울리면 어떤 앱 위로든 알람 UI를 덮는다 —
    /// One UI가 백그라운드 액티비티 시작을 오락가락 차단하므로(2026-11-01
    /// BAL_ALLOW/BAL_BLOCK 로그) 활동 실행이 아니라 오버레이로 해결한다.
    /// 화면이 꺼졌을 때는 FSI 알림이 AlarmActivity를 띄우므로 개입하지 않는다.

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopRinging()
            stopSelf()
            return START_NOT_STICKY
        }
        ringLogId = intent?.getStringExtra(NativeAlarms.EXTRA_LOG_ID) ?: ringLogId
        ringContent = intent?.getStringExtra(NativeAlarms.EXTRA_CONTENT) ?: ringContent
        startRinging()
        return START_NOT_STICKY
    }

    private fun startRinging() {
        if (player?.isPlaying == true) return
        startInForeground()
        raiseVolumeIfSilent()
        requestFocus()
        startPlayer()
        startVibration()
        showOverlayIfNeeded()
    }

    /// 서비스 알림 — 벨소리 울리는 동안 포그라운드 자격을 만족하는 조용한
    /// 상태 표시. 수신자가 게시한 알람 알림과는 별개 id로 취급을 분리한다.
    private fun startInForeground() {
        val notification = Notification.Builder(this, SERVICE_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("↩ Loop")
            .setOngoing(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                SERVICE_NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(SERVICE_NOTIF_ID, notification)
        }
    }

    /// 알람 볼륨 0이면 무음이나 다름없으므로 최소 가청 볼륨로 올린다.
    private fun raiseVolumeIfSilent() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val current = am.getStreamVolume(AudioManager.STREAM_ALARM)
        if (current > 0) return
        val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
        val floor = (max * MIN_VOLUME_RATIO).toInt().coerceIn(1, max)
        runCatching { am.setStreamVolume(AudioManager.STREAM_ALARM, floor, 0) }
    }

    private fun requestFocus() {
        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attrs)
            .build()
        focusRequest = request
        am.requestAudioFocus(request)
    }

    private fun startPlayer() {
        val uri = alarmSoundUri() ?: return
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        for (candidate in urisWithFallback(uri)) {
            player = MediaPlayer()
            try {
                player?.apply {
                    setAudioAttributes(attrs)
                    setDataSource(this@AlarmSoundService, candidate)
                    isLooping = true
                    prepare()
                    start()
                }
                return
            } catch (e: Exception) {
                player?.release()
                player = null
            }
        }
    }

    /// 사용자가 고른 알람음 → 기본 알람음 → 기본 알림음 순으로 시도.
    private fun alarmSoundUri(): Uri =
        RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

    private fun urisWithFallback(primary: Uri): List<Uri> = listOf(
        primary,
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
    ).filterNotNull().distinct()

    private fun startVibration() {
        val v = vibrator() ?: return
        val effect = VibrationEffect.createWaveform(longArrayOf(0, 400, 400, 400), 0)
        v.vibrate(effect)
        // 반드시 필드에 보관 — stopRinging의 cancel이 이 인스턴스를 맞춰야 한다.
        // (2026-11-01: 지역 변수만 써서 확인 후에도 진동이 무한 반복된 버그)
        vibrator = v
    }

    /// 알람 전체 UI를 시스템 오버레이로 띄운다 — 어떤 앱 위에서도, 잠금화면
    /// 위에서도 표시된다. 확인·미루기는 수신자 방송으로 처리해 알림 버튼과
    /// 같은 경로를 태운다.
    private fun showOverlayIfNeeded() {
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (!power.isInteractive) return
        if (!Settings.canDrawOverlays(this)) return
        if (overlayView != null) return

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val view = LayoutInflater.from(this).inflate(R.layout.alarm_activity, null) ?: return
        view.findViewById<Button>(R.id.snoozeButton)?.setOnClickListener {
            sendBroadcast(
                Intent(this, AlarmReceiver::class.java)
                    .setAction(AlarmReceiver.ACTION_SNOOZE)
                    .putExtra(NativeAlarms.EXTRA_LOG_ID, ringLogId)
                    .putExtra(NativeAlarms.EXTRA_CONTENT, ringContent),
            )
        }
        view.findViewById<Button>(R.id.confirmButton)?.setOnClickListener {
            sendBroadcast(
                Intent(this, AlarmReceiver::class.java)
                    .setAction(AlarmReceiver.ACTION_CONFIRM)
                    .putExtra(NativeAlarms.EXTRA_LOG_ID, ringLogId),
            )
        }
        // alarmTime은 레이아웃에서 TextView — Button으로 읽으면 ClassCastException
        // 으로 서비스가 통째로 죽는다. (2026-11-01 실측 크래시)
        view.findViewById<android.widget.TextView>(R.id.alarmTime)?.let {
            it.text = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
                .format(java.util.Date())
        }
        view.findViewById<android.widget.TextView>(R.id.alarmContent)?.text =
            ringContent.ifBlank { getString(R.string.alarm_no_content) }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.OPAQUE,
        )
        runCatching { wm.addView(view, params) }
            .onSuccess { overlayView = view }
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    private fun stopRinging() {
        overlayView?.let { v ->
            runCatching {
                (getSystemService(Context.WINDOW_SERVICE) as WindowManager).removeView(v)
            }
        }
        overlayView = null
        player?.let { p ->
            runCatching { if (p.isPlaying) p.stop() }
            p.release()
        }
        player = null
        vibrator?.cancel()
        vibrator = null
        focusRequest?.let { request ->
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.abandonAudioFocusRequest(request)
        }
        focusRequest = null
    }

    override fun onDestroy() {
        stopRinging()
        super.onDestroy()
    }

    companion object {
        const val ACTION_RING = "com.loop.loop.ALARM_RING"
        const val ACTION_STOP = "com.loop.loop.ALARM_RING_STOP"
        private const val SERVICE_CHANNEL_ID = "loop_alarm_ringing"
        private const val SERVICE_NOTIF_ID = 20261101

        /// "꺼야 멈춤" — 무음 볼륨에서도 들리도록 올리는 최소 비율.
        private const val MIN_VOLUME_RATIO = 0.4

        fun ensureServiceChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(
                    SERVICE_CHANNEL_ID,
                    if (context.resources.configuration.locales[0].language == "ko") "루프 알람 재생"
                    else "Loop alarm playback",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setSound(null, null) },
            )
        }

        fun start(context: Context, logId: String, content: String) {
            val intent = Intent(context, AlarmSoundService::class.java)
                .setAction(ACTION_RING)
                .putExtra(NativeAlarms.EXTRA_LOG_ID, logId)
                .putExtra(NativeAlarms.EXTRA_CONTENT, content)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmSoundService::class.java))
        }
    }
}
