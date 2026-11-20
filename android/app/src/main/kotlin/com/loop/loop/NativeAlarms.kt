package com.loop.loop

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

/// 알람형 루프의 네이티브 예약 — 시계 앱과 같은 setAlarmClock 경로.
/// 알림 배너(One UI가 전체화면을 배너로 바꾸는 문제)를 거치지 않고
/// 전체화면 AlarmActivity를 직접 띄운다. (2026-10-18)
///
/// 예약 정보는 SharedPreferences에도 남겨 부팅 후 재예약한다.
/// - "alarm:<logId>"  → 예약 본문 {"at": ms, "content": "..."}
/// - "snooze:<logId>" → 스누즈된 새 시각(ms) — Dart가 다음 실행 때 DB에 반영
object NativeAlarms {
    const val PREFS = "loop_alarms"
    const val EXTRA_LOG_ID = "logId"
    const val EXTRA_CONTENT = "content"
    private const val ACTION_FIRE = "com.loop.loop.ALARM_FIRE"

    fun schedule(context: Context, logId: String, atMs: Long, content: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // 사용자가 누르면 앱(타임라인)을 연다 — 알람 아이콘의 표시 인텐트.
        val show = PendingIntent.getActivity(
            context, logId.hashCode(),
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val fire = PendingIntent.getBroadcast(
            context, logId.hashCode(),
            Intent(context, AlarmReceiver::class.java)
                .setAction(ACTION_FIRE)
                .putExtra(EXTRA_LOG_ID, logId)
                .putExtra(EXTRA_CONTENT, content)
                .putExtra(EXTRA_AT_MS, atMs),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        // setAlarmClock은 SCHEDULE_EXACT_ALARM 특별권한이 필요 없는
        // 사용자 알람 전용 API — 정확하고 시계 앱과 동일한 신뢰 등급.
        am.setAlarmClock(AlarmManager.AlarmClockInfo(atMs, show), fire)
        prefs(context).edit()
            .putString("alarm:$logId", JSONObject().put("at", atMs).put("content", content).toString())
            .commit()
    }

    /// 절전 중 방송 재전달(프로세스가 도중에 정리되면 시스템이 같은 방송을
    /// 다시 보낸다)을 걸러내는 장치 — "이 예약 시각(atMs)을 처리했는지"로
    /// 판정한다. 재전달은 항상 같은 atMs, 스누즈/재예약은 항상 새 atMs라서
    /// 어떤 타이밍에도 뚫리지 않는다. commit()으로 프로세스 사망에도 유지.
    /// (2026-10-18 알람 중복 울림 버그 2차 수정)
    const val EXTRA_AT_MS = "atMs"

    fun isRedelivery(context: Context, logId: String, atMs: Long): Boolean {
        val handledAt = prefs(context).getLong("handled:$logId", -1L)
        return atMs != -1L && handledAt == atMs
    }

    fun markFired(context: Context, logId: String, atMs: Long) {
        prefs(context).edit().putLong("handled:$logId", atMs).commit()
    }

    fun cancel(context: Context, logId: String) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val fire = PendingIntent.getBroadcast(
            context, logId.hashCode(),
            Intent(context, AlarmReceiver::class.java).setAction(ACTION_FIRE),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        fire?.let { am.cancel(it) }
        prefs(context).edit().remove("alarm:$logId").commit()
    }

    /// 부팅 후 — 살아있는 예약을 되살린다. 시각이 지난 것은 버린다
    /// (Dart의 settleRepeats/settleExpiredLoops가 다음 실행 때 정산).
    fun rescheduleFromPrefs(context: Context) {
        val p = prefs(context)
        val all = p.all
        for ((key, value) in all) {
            if (!key.startsWith("alarm:")) continue
            val logId = key.removePrefix("alarm:")
            val atMs = runCatching { JSONObject(value as String).getLong("at") }.getOrNull() ?: continue
            if (atMs <= System.currentTimeMillis()) {
                p.edit().remove(key).apply()
                continue
            }
            val content = runCatching { JSONObject(value as String).getString("content") }.getOrNull() ?: ""
            schedule(context, logId, atMs, content)
        }
    }

    /// 스누즈 기록 — Dart가 다음 실행 때 DB(loop_at)에 반영하고 치운다.
    fun markSnoozed(context: Context, logId: String, atMs: Long) {
        prefs(context).edit().putLong("snooze:$logId", atMs).apply()
    }

    fun consumeSnoozes(context: Context): Map<String, Long> {
        val p = prefs(context)
        val out = HashMap<String, Long>()
        for ((key, value) in p.all) {
            if (key.startsWith("snooze:") && value is Long) out[key.removePrefix("snooze:")] = value
        }
        if (out.isNotEmpty()) {
            val edit = p.edit()
            for (key in out.keys) edit.remove("snooze:$key")
            edit.apply()
        }
        return out
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
