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
  String get pastTimeHint => 'Esa hora ya pasó: elige una hora futura';

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
  String get recommended => 'Sugerido';

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
  String get presetMonthly => 'Mensual';

  @override
  String get presetYearly => 'Anual';

  @override
  String get presetLadder => 'Escalera';

  @override
  String get ruleLadder => 'Escalera de la curva del olvido';

  @override
  String get curveSteps =>
      '10 min → 1 h → esta noche → mañana → 1 sem → 1 mes · 6 veces';

  @override
  String get fireDate => 'Fecha de disparo';

  @override
  String get unitMonths => 'mes';

  @override
  String get unitYears => 'año';

  @override
  String ruleMonthly(int day, String time) {
    return 'Cada mes el día $day a las $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return 'Cada $n meses el día $day a las $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return 'Cada año el $date a las $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return 'Cada $n años el $date a las $time';
  }

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
  String get mineOnlyTitle => 'Solo mis bucles';

  @override
  String get mineOnlyBack => 'Ver todo';

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
  String get testNotifTitle => 'Prueba · notificación';

  @override
  String get overlayPermTitle => 'Mostrar la alarma sobre otras apps';

  @override
  String get overlayPermBody =>
      'Para sonar a pantalla completa incluso mientras usas otra app, Loop necesita el permiso \"Mostrar sobre otras apps\". Permite en la siguiente pantalla.';

  @override
  String get overlayPermOpen => 'Abrir ajustes';

  @override
  String get testFireDesc => 'Notificación en 5 s · alarma en 20 s';

  @override
  String get testFireSoon => 'Pronto: notificación (5 s) · alarma (20 s)';

  @override
  String get fullScreenHint =>
      'Para ver la alarma a pantalla completa, permite \"Alarmas y recordatorios\".';

  @override
  String get openSettings => 'Abrir ajustes';

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

  @override
  String get statsTitle => 'Tu flujo';

  @override
  String get statsEmpty =>
      'Tu flujo aparece a medida que escribes.\nToca + para dejar tu primer pensamiento.';

  @override
  String statsReturnsLine(int n) {
    return 'Tus pensamientos volvieron a ti $n veces';
  }

  @override
  String get statsReturnsZero =>
      'Pon un bucle y tus pensamientos volverán a ti';

  @override
  String get statsTotalLogs => 'Registros';

  @override
  String get statsActiveDays => 'Días escritos';

  @override
  String get statsStreakNow => 'Racha actual';

  @override
  String get statsStreakBest => 'Mejor racha';

  @override
  String statsDays(int n) {
    return '$n días';
  }

  @override
  String get statsHeatmapCaption => 'Últimas 15 semanas';

  @override
  String get statsHeatmapLess => 'Menos';

  @override
  String get statsHeatmapMore => 'Más';

  @override
  String get statsTopChains => 'Cadenas más largas';

  @override
  String statsChainLinkings(int n) {
    return '$n continuaciones';
  }

  @override
  String get starterQuickTitle => 'Bucle de 10 min';

  @override
  String get starterQuickDesc => 'Escribe ahora y vuelve en 10 minutos';

  @override
  String get starterDailyTitle => 'Una línea cada noche';

  @override
  String get starterDailyDesc => 'Tu día vuelve cada noche a las 9';

  @override
  String get starterWeekTitle => 'Bucle de una semana';

  @override
  String get starterWeekDesc => 'Escribe ahora, revísalo en una semana';

  @override
  String starterInMinutes(int n) {
    return 'en $n min';
  }

  @override
  String starterEveryNight(String time) {
    return 'cada noche a las $time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ Vuelve $when';
  }

  @override
  String get onThisDayTitle => 'Tu yo de entonces';

  @override
  String get onThisDayWeekAgo => 'hace una semana';

  @override
  String get onThisDayMonthAgo => 'hace un mes';

  @override
  String get onThisDayYearAgo => 'hace un año';

  @override
  String get onThisDayChannelName => 'Tu yo de entonces';

  @override
  String get onThisDayChannelDesc =>
      'Cada mañana te trae un registro del pasado';

  @override
  String get onThisDaySetting => 'Nota matinal del pasado';

  @override
  String get onThisDaySettingDesc =>
      'Un registro de hace una semana, un mes o un año vuelve a las 9 AM';

  @override
  String get shareStats => 'Compartir';

  @override
  String get shareCardTagline =>
      'Un diario donde tus pensamientos vuelven a ti';

  @override
  String get shareFail => 'No se pudo crear la tarjeta para compartir';

  @override
  String get loopAttachHeadLabel =>
      '↩ Continúa desde la última entrada de la cadena';

  @override
  String get loopAttachHereLabel => '↩ Se bifurca desde esta entrada';

  @override
  String get loopAttachHereAction => 'Desde aquí';

  @override
  String get loopAttachHeadAction => 'Al final de la cadena';

  @override
  String get todayEvening => 'Esta noche';

  @override
  String get dayEndSetting => 'Hora de cierre del día';

  @override
  String get dayEndSettingDesc =>
      'La opción \"Esta noche\" y el bucle nocturno usan esta hora';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get takeVideo => 'Grabar video';

  @override
  String get videoAttached => 'Video adjunto';

  @override
  String get videoOpenRow => 'Video · toca para reproducir';

  @override
  String get videoPlayFail => 'No se encontró una app para reproducir el video';

  @override
  String get videoTooLong => 'Los videos pueden durar hasta 1 minuto';

  @override
  String get shareChainAction => 'Compartir bucle';

  @override
  String get shareChainTitle => 'Compartir bucle';

  @override
  String get shareCountLogs => 'Registros';

  @override
  String get shareCountPhotos => 'Fotos';

  @override
  String get shareCountVideos => 'Videos';

  @override
  String get shareCountRepeats => 'Bucles';

  @override
  String get shareNameLabel => 'Nombre visible';

  @override
  String get shareNameHint => 'El nombre que verá la otra persona';

  @override
  String get shareStripLocation => 'Enviar sin ubicación';

  @override
  String get shareStripLocationDesc => 'Los lugares y coordenadas no se envían';

  @override
  String get shareStripMedia => 'Enviar sin fotos ni videos';

  @override
  String get shareStripMediaDesc => 'Solo registros de texto';

  @override
  String get shareSendNearby => 'Enviar a un dispositivo cercano';

  @override
  String get shareExportFile => 'Exportar a archivo (.looplog)';

  @override
  String get shareSearching => 'Buscando dispositivos cercanos…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · conectado';
  }

  @override
  String get shareSending => 'Enviando';

  @override
  String get shareHintOffline =>
      'Sin internet ni servidores; normalmente tarda unos segundos.';

  @override
  String get shareSent => 'Enviado';

  @override
  String get shareSendFail => 'No se pudo enviar';

  @override
  String get sharePermTitle => 'Permisos de dispositivos cercanos';

  @override
  String get sharePermBody =>
      'Para encontrar dispositivos cercanos se necesita permiso de ubicación y dispositivos cercanos. Los datos van directos entre dispositivos y no se guardan en ningún sitio.';

  @override
  String receiveFrom(String name) {
    return '$name te envió una cadena';
  }

  @override
  String get receiveTitle => 'Importar cadena';

  @override
  String get receiveBadgeNoLocation => 'Enviada sin ubicación';

  @override
  String get receiveQuestion => '¿Cómo quieres importarla?';

  @override
  String get receiveOnly => 'Importar solo registros';

  @override
  String get receiveOnlyDesc =>
      'La cadena se pega tal cual a tu línea de tiempo. Sin recordatorios.';

  @override
  String get receiveAdopt => 'Adoptar como bucle activo';

  @override
  String get receiveAdoptDesc =>
      'El bucle vuelve a sonar con mis recordatorios, desde ahora en mi horario.';

  @override
  String get receiveImport => 'Importar';

  @override
  String get receiveDecline => 'Rechazar';

  @override
  String get receiveDone => 'Importado';

  @override
  String receiveDoneDesc(int count) {
    return '$count registros quedaron en tu línea de tiempo.';
  }

  @override
  String get receiveAdoptedTitle => '🔁 Adoptado como bucle activo';

  @override
  String get receiveAdoptedDesc =>
      'El historial queda igual; los recordatorios siguen mi horario.';

  @override
  String receiveNextFire(String time) {
    return 'Próximo aviso $time';
  }

  @override
  String get viewChainAction => 'Ver cadena';

  @override
  String get laterAction => 'Después';

  @override
  String get receiveFail => 'No se pudo importar';

  @override
  String get shareTapToSend => 'Toca para enviar';

  @override
  String get shareWaitingReceiver =>
      'En el otro teléfono, activa Ajustes › Recibir de dispositivos cercanos y aparecerá aquí';

  @override
  String get shareNotFound => 'No se encontró ningún dispositivo cercano';

  @override
  String get shareRetry => 'Buscar de nuevo';

  @override
  String get receiveSetting => 'Recibir de dispositivos cercanos';

  @override
  String get receiveSettingDesc =>
      'Con la app abierta, los dispositivos cercanos ven tu nombre visible';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return 'Quedan unos $seconds s';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return 'Quedan unos $minutes min';
  }

  @override
  String get shareSlowHint =>
      'Se está enviando lento por Bluetooth. Cancela, activa el Wi-Fi en ambos teléfonos y vuelve a enviar: es mucho más rápido.';

  @override
  String get shareStalled =>
      'No hubo progreso durante un rato y se detuvo. Acerca los teléfonos y vuelve a enviar.';

  @override
  String receiveIncoming(String name) {
    return '$name está enviando…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return 'Se interrumpió el envío de $name';
  }

  @override
  String get shareCleanTitle => 'Borrar archivos temporales de envío';

  @override
  String shareCleanDesc(String size) {
    return '$size · archivos incompletos y temporales';
  }

  @override
  String get shareCleanEmpty => 'No hay nada que borrar';

  @override
  String get shareCleanConfirm =>
      'Se conservan los archivos de una transferencia en curso.';

  @override
  String get shareCleanAction => 'Borrar';

  @override
  String shareCleanDone(String size) {
    return 'Se borraron $size';
  }

  @override
  String get alarmPermTitle => 'Permite que las alarmas aparezcan en pantalla';

  @override
  String get alarmPermBody =>
      'Ahora la alarma solo suena y no aparece en pantalla. Permite las \'notificaciones a pantalla completa\' para que aparezca sobre la pantalla de bloqueo, aunque esté apagada.';

  @override
  String get settingsAppInfo => 'Información';

  @override
  String get guideOpen => 'Cómo usar Loop';

  @override
  String get guideOpenDesc => 'Todas las funciones, con imágenes';

  @override
  String get guideTitle => 'Cómo usar Loop';

  @override
  String get guideIntroTitle => 'Qué es Loop';

  @override
  String get guideIntroBody =>
      'Un diario que hace volver tus pensamientos pasados. Escribe lo que piensas, crea un bucle y el registro vuelve cuando tú elijas.';

  @override
  String get guideWriteTitle => 'Escribir un registro';

  @override
  String get guideWriteBody =>
      'Toca + abajo a la derecha para escribir lo que piensas. Adjunta fotos o un vídeo de hasta 1 minuto. El lugar y el tiempo se guardan solos (desactívalo en Ajustes › Ubicación).';

  @override
  String get guideLoopTitle => 'Crear un bucle — que vuelva';

  @override
  String get guideLoopBody =>
      'Registro ⋯ › ↩ Bucle. \'Una vez\' lo trae de vuelta una vez (se sugiere una hora según la curva del olvido). Una notificación avisa una vez; una alarma suena hasta que la confirmas.';

  @override
  String get guideRepeatTitle => 'Bucles que se repiten';

  @override
  String get guideRepeatBody =>
      'Elige \'Repetir\' para que vuelva cada 10 minutos, a diario, entre semana, cada mes y más. Cada vez aparece un hueco para continuar el registro. Para terminar: ⋯ › Detener bucle.';

  @override
  String get guideFlowTitle => 'Continuar y ver la cadena';

  @override
  String get guideFlowBody =>
      'Escribe sobre un registro que volvió y se une a una cadena con una línea morada. Con ⋯ › Ver bucle lo ves desde el primer registro en una sola línea. El botón de arriba te devuelve a la línea de tiempo.';

  @override
  String get guideUpcomingTitle => 'Próximos 7 días';

  @override
  String get guideUpcomingBody =>
      'Toca el primer icono de arriba (Próximos · 7 días) para ver todos los bucles que volverán en los próximos 7 días.';

  @override
  String get guideRhythmTitle => 'Ritmo de mañana y noche';

  @override
  String get guideRhythmBody =>
      'Nota matinal del pasado: a las 9 h, registros de hace una semana, un mes y un año. Hora de cierre del día: la etiqueta \'Esta noche\' y los bucles nocturnos usan esta hora. Cambia ambas en Ajustes.';

  @override
  String get guideShareTitle => 'Compartir bucle — a quien tienes al lado';

  @override
  String get guideShareBody =>
      'Registro ⋯ › Compartir bucle › Enviar a un dispositivo cercano. Llega directo al teléfono de al lado, sin internet ni servidor. Quien recibe activa Ajustes › Recibir de dispositivos cercanos. La ubicación se excluye por defecto.';

  @override
  String get guideBackupTitle => 'Copia — exportar e importar';

  @override
  String get guideBackupBody =>
      'Ajustes › Exportar todo guarda registros, fotos, vídeos y repeticiones en un archivo .looplog. En un teléfono nuevo usa Ajustes › Importar; se omiten los registros que ya tienes. Exporta de vez en cuando.';

  @override
  String get guideStatsTitle => 'Tu flujo, búsqueda y fechas';

  @override
  String get guideStatsBody =>
      'Usa los iconos de arriba. Buscar encuentra contenido y lugares, Ir a una fecha abre ese día y Tu flujo muestra cuántas veces volvieron tus ideas, tus rachas y tus cadenas más largas.';

  @override
  String get guideAlarmTitle => 'Que las alarmas aparezcan en pantalla';

  @override
  String get guideAlarmBody =>
      'Para que las alarmas aparezcan sobre la pantalla de bloqueo, permite las \'notificaciones a pantalla completa\'. Cuando Loop lo pida, toca Abrir ajustes y activa Loop. Sin eso, solo suenan. Pruébalo con Ajustes › Probar un aviso.';

  @override
  String get coachSkip => 'Omitir';

  @override
  String get coachGotIt => 'Entendido';

  @override
  String get coachWriteTitle => 'Escribe lo que tienes en mente ahora';

  @override
  String get coachWriteBody =>
      'Sin títulos ni carpetas. Deja el pensamiento tal como te viene.';

  @override
  String get coachReserveTitle => 'Elige cuándo volver a verlo';

  @override
  String get coachReserveBody =>
      'En 10 minutos, esta noche, en una semana… elige cuándo debe volver este pensamiento.';

  @override
  String get coachSaveTitle => 'Guarda y tu bucle estará listo';

  @override
  String get coachSaveBody =>
      'Este pensamiento volverá a la hora que elegiste.';

  @override
  String get coachReturnTitle => 'Cuando vuelva, sigue escribiendo';

  @override
  String get coachReturnBody =>
      'Cuando llegue el aviso, toca «Escribir ahora». Tus ideas se enlazan en una cadena.';

  @override
  String get coachArmTitle =>
      'También puedes poner en bucle registros anteriores';

  @override
  String get coachArmBody =>
      'Toca «Activar bucle» y este pensamiento volverá a ti.';

  @override
  String get coachReplay => 'Ver el tutorial de nuevo';

  @override
  String get coachReplayDesc => 'Repite la guía para crear tu primer bucle';

  @override
  String get pcLinkSettingTitle => 'Conexión con PC';

  @override
  String get pcLinkSettingOff => 'Sin conectar';

  @override
  String get pcLinkSettingConnected => 'Conectado';

  @override
  String get pcLinkTitle => 'Conexión con PC';

  @override
  String get pcLinkIntro =>
      'Permite que Claude Code en tu Mac busque en tu diario. Una vez conectado, la conexión se mantiene 1 hora después del último uso, aunque apagues la pantalla o uses otras apps.';

  @override
  String get pcLinkHostLabel => 'Dirección del PC (IP)';

  @override
  String get pcLinkHostHint => 'p. ej. 192.168.0.8';

  @override
  String get pcLinkConnect => 'Conectar';

  @override
  String get pcLinkConnecting => 'Conectando…';

  @override
  String get pcLinkCodeTitle => 'Código de emparejamiento';

  @override
  String get pcLinkCodeBody =>
      'Pide a Claude en el PC que muestre el código de conexión e introduce los 8 dígitos.';

  @override
  String get pcLinkCodeHint => '8 dígitos';

  @override
  String get pcLinkCodeSubmit => 'Enviar';

  @override
  String get pcLinkConnectedTitle => 'Conectado';

  @override
  String get pcLinkConnectedBody =>
      'Claude ya puede buscar en tu diario. La conexión se mantiene 1 hora después del último uso.';

  @override
  String get pcLinkQueries => 'Consultas respondidas';

  @override
  String get pcLinkDisconnect => 'Desconectar';

  @override
  String get pcLinkUnpair => 'Desemparejar';

  @override
  String get pcLinkErrRefused =>
      'No se puede conectar: revisa la dirección del PC y que Claude Code esté en ejecución.';

  @override
  String get pcLinkErrTimeout =>
      'Sin respuesta: comprueba que estás en la misma red Wi-Fi que el PC.';

  @override
  String get pcLinkErrBadHost => 'El formato de la dirección no es válido.';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'Código incorrecto (quedan $left)';
  }

  @override
  String get pcLinkErrTooMany =>
      'Demasiados intentos: prueba de nuevo en un momento.';

  @override
  String get pcLinkErrBusy => 'Ya hay otro teléfono conectado.';

  @override
  String get pcLinkErrCodeExpired =>
      'Código caducado: pide uno nuevo a Claude y reconecta.';

  @override
  String get pcLinkErrDisconnected => 'Conexión perdida.';

  @override
  String get pcLinkReconnecting => 'Conexión perdida. Reconectando…';

  @override
  String get guidePcTitle => 'Busca con Claude desde tu PC';

  @override
  String get guidePcBody =>
      'Preparación — instala el plugin de Loop en Claude Code de tu ordenador. Escribe estas dos líneas en Claude Code: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. Luego solo dile a Claude «conecta mi teléfono»: te dará la dirección y un código de 8 dígitos. ① En Ajustes → Conexión con PC, introduce esa dirección y conéctate ② introduce el código y quedarás conectado — a partir de ahí se reconecta automáticamente. Tus registros se quedan en el móvil: solo la búsqueda viaja por tu Wi-Fi.';
}
