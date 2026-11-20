package com.loop.loop

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/// 알람 전체화면 — fullScreenIntent 알림이 잠금/화면 꺼짐 상태에서 띄운다.
/// 소리·진동은 알림 채널(알람 사운드 + FLAG_INSISTENT)이 담당하므로
/// 액티비티는 UI와 버튼 처리만 한다. 확인·스누즈 시 알림을 취소해 소리를 멈춘다.
/// (2026-10-30)
class AlarmActivity : Activity() {
    private var logId: String = ""
    private var content: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 잠금 화면 위에 표시 + 화면 켜기 (API 27+, 그 전 플래그 병행)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        setContentView(R.layout.alarm_activity)

        logId = intent.getStringExtra(NativeAlarms.EXTRA_LOG_ID) ?: ""
        content = intent.getStringExtra(NativeAlarms.EXTRA_CONTENT) ?: ""

        findViewById<TextView>(R.id.alarmTime).text =
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        findViewById<TextView>(R.id.alarmContent).text =
            content.ifBlank { getString(R.string.alarm_no_content) }
        findViewById<Button>(R.id.snoozeButton).setOnClickListener { onSnooze() }
        findViewById<Button>(R.id.confirmButton).setOnClickListener { onConfirm() }
    }

    private fun onSnooze() {
        val at = System.currentTimeMillis() + SNOOZE_MS
        NativeAlarms.schedule(this, logId, at, content)
        NativeAlarms.markSnoozed(this, logId, at)
        finish()
    }

    private fun onConfirm() {
        finish()
    }

    override fun onDestroy() {
        // 확인·스누즈 어느 쪽이든 알림과 벨소리를 정리.
        AlarmSoundService.stop(this)
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(logId.hashCode())
        super.onDestroy()
    }

    companion object {
        private const val SNOOZE_MS = 10L * 60 * 1000
    }
}
