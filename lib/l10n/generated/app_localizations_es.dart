// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get emptyTimeline =>
      'Aún no hay registros.\nDeja tu primer pensamiento con +.';

  @override
  String get emptyAtDate =>
      'No hay registros de ese día.\nCambia la fecha arriba o vuelve a lo último.';

  @override
  String get jumpToDate => 'Ir a una fecha';

  @override
  String get backToLatest => 'Volver a lo último';

  @override
  String get searchHint => 'Buscar contenido y lugares';

  @override
  String get searchEmpty => 'Sin resultados';

  @override
  String get sortRelevance => 'Relevancia';

  @override
  String get sortRecent => 'Más recientes';

  @override
  String get editContent => 'Editar contenido';

  @override
  String get changeTime => 'Cambiar hora';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get stop => 'Detener';

  @override
  String get deleteLogTitle => 'Eliminar registro';

  @override
  String get deleteLogMessage =>
      '¿Eliminar este registro? Los registros continuados se quedan.';

  @override
  String get stopRepeatTitle => 'Detener bucle';

  @override
  String stopRepeatMessage(String rule) {
    return '¿Detener el bucle $rule?\nSe cancelan los próximos avisos; las notas ya creadas se quedan.';
  }

  @override
  String get composeHint => 'Qué piensas ahora…';

  @override
  String forkOf(String time) {
    return '↩ Continuar el registro de $time';
  }

  @override
  String get saveLog => 'Guardar registro';

  @override
  String get attachPhoto => 'Adjuntar foto';

  @override
  String get reserveAlarm => 'Programar aviso';

  @override
  String get alarmTitle => '⏰ Programar aviso';

  @override
  String get tapToChangeTime => 'Toca para cambiar fecha y hora';

  @override
  String get in10min => 'En 10 min';

  @override
  String get in1hour => 'En 1 h';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get nextWeek => 'Semana que viene';

  @override
  String get in1month => 'En un mes';

  @override
  String loopCurveHint(int n, String interval) {
    return 'Repaso #$n de la curva del olvido · sugerido $interval';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String get notifyAtThisTime => 'Avísame a esta hora';

  @override
  String get repeatTitle => '↩ Bucle';

  @override
  String get repeatDesc =>
      'Con la repetición activada, en cada aviso se crea una continuación de esta nota. Puedes pararla cuando quieras.';

  @override
  String get preset10min => '10 min';

  @override
  String get preset30min => '30 min';

  @override
  String get preset1hour => '1 hora';

  @override
  String get preset3hours => '3 horas';

  @override
  String get preset6hours => '6 horas';

  @override
  String get presetDaily => 'Cada día';

  @override
  String get fireTime => 'Hora de disparo';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitHours => 'h';

  @override
  String nextFire(String time, String rule) {
    return 'Próxima $time · luego $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return 'Cada $n min';
  }

  @override
  String ruleEveryHours(int n) {
    return 'Cada $n h';
  }

  @override
  String ruleDaily(String time) {
    return 'Cada día a las $time';
  }

  @override
  String ruleWeekday(String time) {
    return 'Días laborables a las $time';
  }

  @override
  String get presetWeekday => 'Días laborables';

  @override
  String get upcomingTitle => 'Próximos · 7 días';

  @override
  String get upcomingEmpty => 'No hay bucles programados esta semana';

  @override
  String get noContent => '(sin contenido)';

  @override
  String continuedFrom(String time) {
    return '↩ Continuado de $time';
  }

  @override
  String get locationRecorded => 'Ubicación guardada';

  @override
  String repeatNth(int n) {
    return 'Bucle n.º $n';
  }

  @override
  String get repeatEnded => 'Bucle terminado';

  @override
  String get loopAction => '↩ Bucle';

  @override
  String get loopWriteNow => 'Escribir ahora';

  @override
  String get loopAgain => 'Avisarme';

  @override
  String get loopModeOnce => 'Una vez';

  @override
  String get loopModeRepeat => 'Repetir';

  @override
  String loopNextShort(String time) {
    return 'Próximo $time';
  }

  @override
  String loopFireCount(int n) {
    return 'Ha vuelto $n veces';
  }

  @override
  String get loopJump => 'Ir al original';

  @override
  String get loopStop => 'Detener bucle';

  @override
  String get loopEndedInfo => 'Este bucle terminó';

  @override
  String get loopViewAction => 'Ver bucle';

  @override
  String get loopWriteAction => 'Escribir';

  @override
  String get loopViewBack => 'Volver a la línea de tiempo';

  @override
  String get locationCapture => 'Ubicación';

  @override
  String get locationCaptureDesc => 'Adjuntar lugar y clima automáticamente';

  @override
  String get loopArm => 'Activar bucle';

  @override
  String get emptyWriteHint => 'Vacío · toca para escribir';

  @override
  String get openInYoutube => 'Abrir en YouTube';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsData => 'Datos';

  @override
  String get defaultBrowser => 'Navegador predeterminado';

  @override
  String get defaultBrowserDesc =>
      'Los enlaces web se abrirán en este navegador';

  @override
  String get systemDefault => 'Predeterminado del sistema';

  @override
  String get browserEmpty => 'No hay navegadores instalados';

  @override
  String get exportLogs => 'Exportar todo';

  @override
  String get exportAllDesc =>
      'Registros, fotos y repeticiones en un solo archivo .looplog';

  @override
  String get exporting => 'Exportando…';

  @override
  String get exportDone => 'Exportado';

  @override
  String get exportCancel => 'Guardado cancelado';

  @override
  String get exportFail => 'No se pudo guardar el archivo';

  @override
  String get importLogs => 'Importar';

  @override
  String get importAllDesc =>
      'Restaurar desde un archivo .looplog · los registros existentes se omiten';

  @override
  String get importConfirmMessage =>
      'Mantiene lo que ya tienes y añade los registros del archivo.\nLos registros con el mismo ID se omiten, así que importar el mismo archivo dos veces nunca duplica.';

  @override
  String get importing => 'Importando…';

  @override
  String importDone(int logs, int repeats) {
    return 'Importados $logs registros · $repeats repeticiones';
  }

  @override
  String get importCancel => 'Importación cancelada';

  @override
  String get importEmpty => 'Nada que importar';

  @override
  String get importFail => 'No se pudo leer el archivo .looplog';

  @override
  String get howNotify => '¿Cómo te aviso?';

  @override
  String get modeNotif => 'Notificación';

  @override
  String get modeNotifDesc =>
      'Avisa una vez y para. Predeterminada — recordatorio suave';

  @override
  String get modeAlarm => 'Alarma';

  @override
  String get modeAlarmDesc =>
      'Suena hasta que la apagues, incluso en silencio. Para bucles importantes';

  @override
  String get snoozeAction => 'Otra vez en 10 min';

  @override
  String get notifAlarmChannelName => 'Alarmas de bucle';

  @override
  String get testFire => 'Probar un aviso';

  @override
  String get testFireDesc => 'Notificación en 5 s · alarma en 20 s';

  @override
  String get testFireSoon => 'Pronto: notificación (5 s) · alarma (20 s)';

  @override
  String get detailOriginal => 'Registro original';

  @override
  String get detailPlace => 'Lugar';

  @override
  String get detailWeather => 'Tiempo';

  @override
  String get detailPhotos => 'Fotos';

  @override
  String photoCount(int n) {
    return '$n fotos';
  }

  @override
  String get detailNoContext => 'Sin ubicación, tiempo ni fotos';

  @override
  String get detailRecord => 'Registro';

  @override
  String get unknown => 'Desconocido';

  @override
  String get yesterday => 'Ayer';

  @override
  String get wmoClear => 'Despejado';

  @override
  String get wmoPartly => 'Parcialmente nublado';

  @override
  String get wmoCloudy => 'Nublado';

  @override
  String get wmoFog => 'Niebla';

  @override
  String get wmoDrizzle => 'Llovizna';

  @override
  String get wmoRain => 'Lluvia';

  @override
  String get wmoSnow => 'Nieve';

  @override
  String get wmoThunder => 'Tormenta';

  @override
  String get wmoUnknown => 'Desconocido';

  @override
  String get notifRepeatTitle => '↩ Bucle';

  @override
  String get notifFallbackBody => 'Hora de que vuelva el bucle';

  @override
  String get notifConfirm => 'Entendido';

  @override
  String get notifChannelName => 'Bucles';

  @override
  String get notifChannelDesc => 'Te avisa cuando un bucle vuelve';
}
