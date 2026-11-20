// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get emptyTimeline =>
      'Ancora nessuna voce.\nTocca + per il primo pensiero.';

  @override
  String get emptyAtDate =>
      'Nessuna voce in quel periodo.\nCambia data sopra o torna alle più recenti.';

  @override
  String get jumpToDate => 'Vai alla data';

  @override
  String get backToLatest => 'Torna alle recenti';

  @override
  String get searchHint => 'Cerca testo e luoghi';

  @override
  String get searchEmpty => 'Nessun risultato';

  @override
  String get sortRelevance => 'Rilevanza';

  @override
  String get sortRecent => 'Più recenti';

  @override
  String get editContent => 'Modifica testo';

  @override
  String get changeTime => 'Cambia ora';

  @override
  String get deleteAction => 'Elimina';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get stop => 'Ferma';

  @override
  String get deleteLogTitle => 'Elimina voce';

  @override
  String get deleteLogMessage =>
      'Eliminare questa voce? Le continuazioni restano.';

  @override
  String get stopRepeatTitle => 'Ferma Loop';

  @override
  String stopRepeatMessage(String rule) {
    return 'Fermare il loop $rule?\nLe prossime attivazioni verranno annullate, le voci già create restano.';
  }

  @override
  String get composeHint => 'Pensiero di adesso…';

  @override
  String forkOf(String time) {
    return '↩ Continui da $time';
  }

  @override
  String get saveLog => 'Salva la voce';

  @override
  String get attachPhoto => 'Allega foto';

  @override
  String get reserveAlarm => 'Promemoria';

  @override
  String get alarmTitle => '⏰ Promemoria';

  @override
  String get tapToChangeTime => 'Tocca per cambiare data e ora';

  @override
  String get pastTimeHint => 'È già passata — scegli un orario futuro';

  @override
  String get in10min => 'Tra 10 min';

  @override
  String get in1hour => 'Tra 1 ora';

  @override
  String get tomorrow => 'Domani';

  @override
  String get nextWeek => 'Prossima settimana';

  @override
  String get in1month => 'Tra un mese';

  @override
  String loopCurveHint(int n, String interval) {
    return 'Richiamo n°$n · suggerito $interval';
  }

  @override
  String get recommended => 'Suggerito';

  @override
  String get custom => 'Personalizzato';

  @override
  String get notifyAtThisTime => 'Avvisami a quest\'ora';

  @override
  String get repeatTitle => '↩ Loop';

  @override
  String get repeatDesc =>
      'Con un loop attivo, a ogni attivazione viene creata una continuazione di questa voce. Puoi fermarlo quando vuoi.';

  @override
  String get preset10min => '10 min';

  @override
  String get preset30min => '30 min';

  @override
  String get preset1hour => '1 ora';

  @override
  String get preset3hours => '3 ore';

  @override
  String get preset6hours => '6 ore';

  @override
  String get presetDaily => 'Ogni giorno';

  @override
  String get fireTime => 'Orario';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitHours => 'ore';

  @override
  String nextFire(String time, String rule) {
    return 'Prossimo $time · poi $rule';
  }

  @override
  String ruleEveryMinutes(int n) {
    return 'Ogni $n min';
  }

  @override
  String ruleEveryHours(int n) {
    return 'Ogni $n ore';
  }

  @override
  String ruleDaily(String time) {
    return 'Ogni giorno alle $time';
  }

  @override
  String ruleWeekday(String time) {
    return 'Nei feriali alle $time';
  }

  @override
  String get presetWeekday => 'Feriali';

  @override
  String get presetMonthly => 'Ogni mese';

  @override
  String get presetYearly => 'Ogni anno';

  @override
  String get presetLadder => 'Scala';

  @override
  String get ruleLadder => 'Scala della curva dell\'oblio';

  @override
  String get curveSteps =>
      '10 min → 1 ora → stasera → domani → 1 sett → 1 mese · 6 volte';

  @override
  String get fireDate => 'Giorno';

  @override
  String get unitMonths => 'mesi';

  @override
  String get unitYears => 'anni';

  @override
  String ruleMonthly(int day, String time) {
    return 'Il $day di ogni mese alle $time';
  }

  @override
  String ruleEveryMonths(int n, int day, String time) {
    return 'Ogni $n mesi il $day alle $time';
  }

  @override
  String ruleYearly(String date, String time) {
    return 'Ogni anno il $date alle $time';
  }

  @override
  String ruleEveryYears(int n, String date, String time) {
    return 'Ogni $n anni il $date alle $time';
  }

  @override
  String get upcomingTitle => 'In arrivo · 7 giorni';

  @override
  String get upcomingEmpty => 'Nessun loop previsto questa settimana';

  @override
  String get noContent => '(nessun contenuto)';

  @override
  String continuedFrom(String time) {
    return '↩ Continuato da $time';
  }

  @override
  String get locationRecorded => 'Posizione salvata';

  @override
  String repeatNth(int n) {
    return 'Loop n°$n';
  }

  @override
  String get repeatEnded => 'Loop terminato';

  @override
  String get loopAction => '↩ Loop';

  @override
  String get loopWriteNow => 'Continua ora';

  @override
  String get loopAgain => 'Avvisami di nuovo';

  @override
  String get loopModeOnce => 'Una volta';

  @override
  String get loopModeRepeat => 'Ripeti';

  @override
  String loopNextShort(String time) {
    return 'Prossimo $time';
  }

  @override
  String loopFireCount(int n) {
    return 'Tornato $n volte finora';
  }

  @override
  String get loopJump => 'Vai all\'originale';

  @override
  String get loopStop => 'Ferma il loop';

  @override
  String get loopEndedInfo => 'Questo loop è terminato';

  @override
  String get loopViewAction => 'Vedi la catena';

  @override
  String get loopWriteAction => 'Scrivi';

  @override
  String get loopViewBack => 'Torna indietro';

  @override
  String get mineOnlyTitle => 'Solo i miei loop';

  @override
  String get mineOnlyBack => 'Mostra tutto';

  @override
  String get locationCapture => 'Posizione';

  @override
  String get locationCaptureDesc =>
      'Registra automaticamente luogo e meteo con la voce';

  @override
  String get loopArm => 'Attiva loop';

  @override
  String get emptyWriteHint => 'Vuoto · tocca per scrivere';

  @override
  String get openInYoutube => 'Apri in YouTube';

  @override
  String get openInBrowser => 'Apri nel browser';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsData => 'Dati';

  @override
  String get defaultBrowser => 'Browser predefinito';

  @override
  String get defaultBrowserDesc => 'I link si apriranno con questo browser';

  @override
  String get systemDefault => 'Predefinito di sistema';

  @override
  String get browserEmpty => 'Nessun browser installato';

  @override
  String get exportLogs => 'Esporta tutto';

  @override
  String get exportAllDesc => 'Voci, foto e loop in un unico file .looplog';

  @override
  String get exporting => 'Esportazione…';

  @override
  String get exportDone => 'Esportato';

  @override
  String get exportCancel => 'Esportazione annullata';

  @override
  String get exportFail => 'Impossibile salvare il file';

  @override
  String get importLogs => 'Importa';

  @override
  String get importAllDesc =>
      'Ripristina da un file .looplog · le voci già presenti vengono saltate';

  @override
  String get importConfirmMessage =>
      'Le voci esistenti restano, si aggiungono quelle del file.\nLe voci con lo stesso ID vengono saltate: reimportare non crea duplicati.';

  @override
  String get importing => 'Importazione…';

  @override
  String importDone(int logs, int repeats) {
    return 'Importate $logs voci · $repeats loop';
  }

  @override
  String get importCancel => 'Importazione annullata';

  @override
  String get importEmpty => 'Niente da importare';

  @override
  String get importFail => 'Impossibile leggere il file .looplog';

  @override
  String get howNotify => 'Come ti avviso?';

  @override
  String get modeNotif => 'Notifica';

  @override
  String get modeNotifDesc =>
      'Un avviso e basta. Predefinito — promemoria leggero';

  @override
  String get modeAlarm => 'Sveglia';

  @override
  String get modeAlarmDesc =>
      'Suona finché non la fermi, anche in silenzio. Per i loop importanti';

  @override
  String get snoozeAction => 'Ancora tra 10 min';

  @override
  String get notifAlarmChannelName => 'Allarmi Loop';

  @override
  String get testFire => 'Prova un avviso';

  @override
  String get testNotifTitle => 'Prova · notifica';

  @override
  String get overlayPermTitle => 'Mostra la sveglia sopra le altre app';

  @override
  String get overlayPermBody =>
      'Per suonare a schermo intero anche mentre usi un\'altra app, Loop richiede il permesso \"Mostra sopra altre app\". Consenti nella schermata successiva.';

  @override
  String get overlayPermOpen => 'Apri impostazioni';

  @override
  String get testFireDesc => 'Notifica tra 5 s · allarme tra 20 s';

  @override
  String get testFireSoon => 'In arrivo: notifica (5 s) · allarme (20 s)';

  @override
  String get fullScreenHint =>
      'Per l\'allarme a schermo intero, consenti \"Allarmi e promemoria\".';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get detailOriginal => 'Voce originale';

  @override
  String get detailPlace => 'Luogo';

  @override
  String get detailWeather => 'Meteo';

  @override
  String get detailPhotos => 'Foto';

  @override
  String photoCount(int n) {
    return '$n foto';
  }

  @override
  String get detailNoContext => 'Nessuna posizione, meteo o foto';

  @override
  String get detailRecord => 'Dettagli';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get yesterday => 'Ieri';

  @override
  String get wmoClear => 'Sereno';

  @override
  String get wmoPartly => 'Poco nuvoloso';

  @override
  String get wmoCloudy => 'Nuvoloso';

  @override
  String get wmoFog => 'Nebbia';

  @override
  String get wmoDrizzle => 'Pioviggine';

  @override
  String get wmoRain => 'Pioggia';

  @override
  String get wmoSnow => 'Neve';

  @override
  String get wmoThunder => 'Temporale';

  @override
  String get wmoUnknown => 'Sconosciuto';

  @override
  String get notifRepeatTitle => '↩ Loop';

  @override
  String get notifFallbackBody => 'È ora di tornare al loop';

  @override
  String get notifConfirm => 'OK';

  @override
  String get notifChannelName => 'Loop';

  @override
  String get notifChannelDesc => 'Ti ricorda quando un loop torna';

  @override
  String get statsTitle => 'Andamento';

  @override
  String get statsEmpty =>
      'Con il tempo vedrai il flusso.\nTocca + per il primo pensiero.';

  @override
  String statsReturnsLine(int n) {
    return 'Il pensiero è tornato $n volte';
  }

  @override
  String get statsReturnsZero => 'Attiva un loop e il pensiero torna';

  @override
  String get statsTotalLogs => 'Voci scritte';

  @override
  String get statsActiveDays => 'Giorni con voci';

  @override
  String get statsStreakNow => 'Serie attuale';

  @override
  String get statsStreakBest => 'Serie migliore';

  @override
  String statsDays(int n) {
    return '$n giorni';
  }

  @override
  String get statsHeatmapCaption => 'Ultime 15 settimane';

  @override
  String get statsHeatmapLess => 'Meno';

  @override
  String get statsHeatmapMore => 'Più';

  @override
  String get statsTopChains => 'La catena più lunga';

  @override
  String statsChainLinkings(int n) {
    return 'Collegata $n volte';
  }

  @override
  String get starterQuickTitle => 'Loop da 10 minuti';

  @override
  String get starterQuickDesc => 'Scrivi ora — torna tra 10 minuti';

  @override
  String get starterDailyTitle => 'Una riga ogni sera';

  @override
  String get starterDailyDesc => 'La tua giornata torna ogni sera alle 9';

  @override
  String get starterWeekTitle => 'Loop di una settimana';

  @override
  String get starterWeekDesc => 'Scrivi ora, rileggi tra una settimana';

  @override
  String starterInMinutes(int n) {
    return 'tra $n min';
  }

  @override
  String starterEveryNight(String time) {
    return 'ogni sera alle $time';
  }

  @override
  String starterComposeBanner(String when) {
    return '↩ Torna $when';
  }

  @override
  String get onThisDayTitle => 'Il te del passato';

  @override
  String get onThisDayWeekAgo => 'una settimana fa';

  @override
  String get onThisDayMonthAgo => 'un mese fa';

  @override
  String get onThisDayYearAgo => 'un anno fa';

  @override
  String get onThisDayChannelName => 'Il te del passato';

  @override
  String get onThisDayChannelDesc =>
      'Ti rivede con un log passato ogni mattina';

  @override
  String get onThisDaySetting => 'Biglietto mattutino del te passato';

  @override
  String get onThisDaySettingDesc =>
      'Un log di una settimana, un mese o un anno fa torna alle 9';

  @override
  String get shareStats => 'Condividi';

  @override
  String get shareCardTagline => 'Un diario dove i pensieri tornano da te';

  @override
  String get shareFail => 'Impossibile creare la card di condivisione';

  @override
  String get loopAttachHeadLabel =>
      '↩ Continua dall\'ultima voce di questa catena';

  @override
  String get loopAttachHereLabel => '↩ Si ramifica da questa voce';

  @override
  String get loopAttachHereAction => 'Da qui';

  @override
  String get loopAttachHeadAction => 'Alla fine della catena';

  @override
  String get todayEvening => 'Stasera';

  @override
  String get dayEndSetting => 'Orario di chiusura della giornata';

  @override
  String get dayEndSettingDesc =>
      'Usato dal chip \"Stasera\" e dal loop serale';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get takeVideo => 'Registra video';

  @override
  String get videoAttached => 'Video allegato';

  @override
  String get videoOpenRow => 'Video · tocca per riprodurre';

  @override
  String get videoPlayFail =>
      'Impossibile trovare un\'app per riprodurre questo video';

  @override
  String get videoTooLong => 'I video possono durare al massimo 1 minuto';

  @override
  String get shareChainAction => 'Condividi Loop';

  @override
  String get shareChainTitle => 'Condividi Loop';

  @override
  String get shareCountLogs => 'Note';

  @override
  String get shareCountPhotos => 'Foto';

  @override
  String get shareCountVideos => 'Video';

  @override
  String get shareCountRepeats => 'Cicli';

  @override
  String get shareNameLabel => 'Nome visualizzato';

  @override
  String get shareNameHint => 'Il nome che vedrà l\'altra persona';

  @override
  String get shareStripLocation => 'Invia senza posizione';

  @override
  String get shareStripLocationDesc =>
      'Luoghi e coordinate non vengono inviati';

  @override
  String get shareStripMedia => 'Invia senza foto e video';

  @override
  String get shareStripMediaDesc => 'Solo note di testo';

  @override
  String get shareSendNearby => 'Invia a un dispositivo vicino';

  @override
  String get shareExportFile => 'Esporta su file (.looplog)';

  @override
  String get shareSearching => 'Ricerca dispositivi vicini…';

  @override
  String shareDeviceConnected(String name) {
    return '$name · connesso';
  }

  @override
  String get shareSending => 'Invio';

  @override
  String get shareHintOffline =>
      'Nessun internet né server — di solito bastano alcuni secondi.';

  @override
  String get shareSent => 'Inviato';

  @override
  String get shareSendFail => 'Invio non riuscito';

  @override
  String get sharePermTitle => 'Permessi dispositivi vicini';

  @override
  String get sharePermBody =>
      'Per trovare i dispositivi vicini servono i permessi di posizione e dispositivi vicini. I dati passano direttamente fra i dispositivi e non vengono salvati da nessuna parte.';

  @override
  String receiveFrom(String name) {
    return '$name ti ha inviato una catena';
  }

  @override
  String get receiveTitle => 'Importa catena';

  @override
  String get receiveBadgeNoLocation => 'Inviata senza posizione';

  @override
  String get receiveQuestion => 'Come vuoi importarla?';

  @override
  String get receiveOnly => 'Importa solo le note';

  @override
  String get receiveOnlyDesc =>
      'La catena si attacca alla timeline così com\'è. Nessun promemoria.';

  @override
  String get receiveAdopt => 'Adotta come ciclo attivo';

  @override
  String get receiveAdoptDesc =>
      'Il ciclo suona di nuovo con i miei promemoria, da subito sul mio orario.';

  @override
  String get receiveImport => 'Importa';

  @override
  String get receiveDecline => 'Rifiuta';

  @override
  String get receiveDone => 'Importato';

  @override
  String receiveDoneDesc(int count) {
    return '$count note sono ora sulla tua timeline.';
  }

  @override
  String get receiveAdoptedTitle => '🔁 Adottato come ciclo attivo';

  @override
  String get receiveAdoptedDesc =>
      'La cronologia resta intatta; i promemoria seguono il mio orario.';

  @override
  String receiveNextFire(String time) {
    return 'Prossimo avviso $time';
  }

  @override
  String get viewChainAction => 'Vedi catena';

  @override
  String get laterAction => 'Più tardi';

  @override
  String get receiveFail => 'Importazione non riuscita';

  @override
  String get shareTapToSend => 'Tocca per inviare';

  @override
  String get shareWaitingReceiver =>
      'Sull\'altro telefono attiva Impostazioni › Ricevi da dispositivi vicini e apparirà qui';

  @override
  String get shareNotFound => 'Nessun dispositivo vicino trovato';

  @override
  String get shareRetry => 'Cerca di nuovo';

  @override
  String get receiveSetting => 'Ricevi da dispositivi vicini';

  @override
  String get receiveSettingDesc =>
      'Con l\'app aperta, i dispositivi vicini vedono il tuo nome visualizzato';

  @override
  String shareProgressDetail(String sent, String total, String speed) {
    return '$sent / $total · $speed/s';
  }

  @override
  String shareEtaSeconds(int seconds) {
    return 'Circa $seconds s rimanenti';
  }

  @override
  String shareEtaMinutes(int minutes) {
    return 'Circa $minutes min rimanenti';
  }

  @override
  String get shareSlowHint =>
      'Invio lento via Bluetooth. Annulla, attiva il Wi-Fi su entrambi i telefoni e invia di nuovo: è molto più veloce.';

  @override
  String get shareStalled =>
      'Nessun progresso per un po\', quindi si è fermato. Avvicina i telefoni e invia di nuovo.';

  @override
  String receiveIncoming(String name) {
    return '$name sta inviando…';
  }

  @override
  String receiveIncomingFailed(String name) {
    return 'L\'invio da $name si è interrotto';
  }

  @override
  String get shareCleanTitle => 'Elimina file temporanei di condivisione';

  @override
  String shareCleanDesc(String size) {
    return '$size · file incompleti e temporanei di invio';
  }

  @override
  String get shareCleanEmpty => 'Niente da eliminare';

  @override
  String get shareCleanConfirm =>
      'I file di un trasferimento in corso vengono mantenuti.';

  @override
  String get shareCleanAction => 'Elimina';

  @override
  String shareCleanDone(String size) {
    return 'Eliminati $size';
  }

  @override
  String get alarmPermTitle =>
      'Consenti agli allarmi di apparire sullo schermo';

  @override
  String get alarmPermBody =>
      'Ora l\'allarme suona soltanto e non appare sullo schermo. Consenti le \'notifiche a schermo intero\' per vederlo sopra la schermata di blocco, anche a schermo spento.';

  @override
  String get settingsAppInfo => 'Informazioni';

  @override
  String get guideOpen => 'Come usare Loop';

  @override
  String get guideOpenDesc => 'Tutte le funzioni, con immagini';

  @override
  String get guideTitle => 'Come usare Loop';

  @override
  String get guideIntroTitle => 'Cos\'è Loop';

  @override
  String get guideIntroBody =>
      'Un diario che fa tornare i tuoi pensieri passati. Scrivi quello che pensi, imposta un loop e la nota torna quando hai scelto.';

  @override
  String get guideWriteTitle => 'Scrivere una nota';

  @override
  String get guideWriteBody =>
      'Tocca + in basso a destra per scrivere quello che pensi. Allega foto o un video fino a 1 minuto. Luogo e meteo vengono salvati da soli (disattivabili nelle Impostazioni).';

  @override
  String get guideLoopTitle => 'Impostare un loop — farla tornare';

  @override
  String get guideLoopBody =>
      'Nota ⋯ › ↩ Loop. \'Una volta\' la fa tornare una volta (viene suggerito un orario secondo la curva dell\'oblio). Una notifica avvisa una volta; una sveglia suona finché non confermi.';

  @override
  String get guideRepeatTitle => 'Loop ripetuti';

  @override
  String get guideRepeatBody =>
      'Scegli \'Ripeti\' per farla tornare ogni 10 minuti, ogni giorno, nei giorni feriali, ogni mese e altro. Ogni volta compare uno spazio per continuare. Per finire: ⋯ › Ferma il loop.';

  @override
  String get guideFlowTitle => 'Continuare e vedere la catena';

  @override
  String get guideFlowBody =>
      'Scrivi su una nota tornata e si unisce a una catena con una linea viola. Con ⋯ › Vedi la catena la vedi dalla prima nota in una sola riga. Il pulsante in alto ti riporta alla timeline.';

  @override
  String get guideUpcomingTitle => 'Prossimi 7 giorni';

  @override
  String get guideUpcomingBody =>
      'Tocca la prima icona in alto (In arrivo · 7 giorni) per vedere tutti i loop che torneranno nei prossimi 7 giorni.';

  @override
  String get guideRhythmTitle => 'Ritmo di mattina e sera';

  @override
  String get guideRhythmBody =>
      'Alle 9 del mattino Loop ti riporta le note di una settimana, un mese e un anno fa. L\'orario di fine giornata serve ai suggerimenti serali e ai loop notturni. Cambiali entrambi nelle Impostazioni.';

  @override
  String get guideShareTitle => 'Condividi Loop — a chi ti sta accanto';

  @override
  String get guideShareBody =>
      'Nota ⋯ › Condividi Loop › Invia a un dispositivo vicino. Arriva dritto al telefono accanto, senza internet né server. Chi riceve attiva Impostazioni › Ricevi da dispositivi vicini. La posizione è esclusa di default.';

  @override
  String get guideBackupTitle => 'Backup — esportare e importare';

  @override
  String get guideBackupBody =>
      'Impostazioni › Esporta tutto salva note, foto, video e ripetizioni in un file .looplog. Su un nuovo telefono usa Impostazioni › Importa: le note già presenti vengono saltate. Esporta ogni tanto.';

  @override
  String get guideStatsTitle => 'Andamento, ricerca e date';

  @override
  String get guideStatsBody =>
      'Usa le icone in alto. La ricerca trova testo e luoghi, Vai alla data apre quel giorno e Andamento mostra quante volte i pensieri sono tornati, le serie di giorni e le catene più lunghe.';

  @override
  String get guideAlarmTitle => 'Far apparire gli allarmi sullo schermo';

  @override
  String get guideAlarmBody =>
      'Perché gli allarmi compaiano sopra la schermata di blocco, consenti le \'notifiche a schermo intero\'. Quando Loop lo chiede, tocca Apri impostazioni e attiva Loop. Senza, suonano soltanto. Provalo con Impostazioni › Prova un avviso.';

  @override
  String get coachSkip => 'Salta';

  @override
  String get coachGotIt => 'Ho capito';

  @override
  String get coachWriteTitle => 'Scrivi ciò che hai in mente adesso';

  @override
  String get coachWriteBody =>
      'Niente titoli, niente cartelle. Annota il pensiero così come arriva.';

  @override
  String get coachReserveTitle => 'Scegli quando rivederlo';

  @override
  String get coachReserveBody =>
      'Tra 10 minuti, stasera, tra una settimana… scegli quando questo pensiero deve tornare.';

  @override
  String get coachSaveTitle => 'Salva e il loop è pronto';

  @override
  String get coachSaveBody =>
      'Questo pensiero tornerà all\'ora che hai scelto.';

  @override
  String get coachReturnTitle => 'Quando torna, continua a scrivere';

  @override
  String get coachReturnBody =>
      'Quando arriva il promemoria, tocca «Continua ora». I pensieri si uniscono in una catena.';

  @override
  String get coachArmTitle => 'Puoi mettere in loop anche le voci passate';

  @override
  String get coachArmBody =>
      'Tocca «Attiva loop» e questo pensiero tornerà da te.';

  @override
  String get coachReplay => 'Rivedi il tutorial';

  @override
  String get coachReplayDesc => 'Ripeti la guida per creare il primo loop';

  @override
  String get pcLinkSettingTitle => 'Connessione al PC';

  @override
  String get pcLinkSettingOff => 'Non connesso';

  @override
  String get pcLinkSettingConnected => 'Connesso';

  @override
  String get pcLinkTitle => 'Connessione al PC';

  @override
  String get pcLinkIntro =>
      'Consente a Claude Code sul Mac di cercare nel tuo diario. Una volta connesso, il collegamento resta attivo per 1 ora dall\'ultimo utilizzo, anche a schermo spento o in altre app.';

  @override
  String get pcLinkHostLabel => 'Indirizzo del PC (IP)';

  @override
  String get pcLinkHostHint => 'es. 192.168.0.8';

  @override
  String get pcLinkConnect => 'Connetti';

  @override
  String get pcLinkConnecting => 'Connessione…';

  @override
  String get pcLinkCodeTitle => 'Codice di abbinamento';

  @override
  String get pcLinkCodeBody =>
      'Chiedi a Claude sul PC di mostrare il codice di connessione e inserisci le 8 cifre.';

  @override
  String get pcLinkCodeHint => '8 cifre';

  @override
  String get pcLinkCodeSubmit => 'Invia';

  @override
  String get pcLinkConnectedTitle => 'Connesso';

  @override
  String get pcLinkConnectedBody =>
      'Claude ora può cercare nel tuo diario. Il collegamento resta attivo per 1 ora dall\'ultimo utilizzo.';

  @override
  String get pcLinkQueries => 'Richieste servite';

  @override
  String get pcLinkDisconnect => 'Disconnetti';

  @override
  String get pcLinkUnpair => 'Dissocia abbinamento';

  @override
  String get pcLinkErrRefused =>
      'Impossibile connettersi: controlla l\'indirizzo del PC e che Claude Code sia in esecuzione.';

  @override
  String get pcLinkErrTimeout =>
      'Nessuna risposta: verifica di essere sulla stessa Wi-Fi del PC.';

  @override
  String get pcLinkErrBadHost => 'Il formato dell\'indirizzo non è valido.';

  @override
  String pcLinkErrCodeWrong(int left) {
    return 'Codice errato ($left tentativi rimasti)';
  }

  @override
  String get pcLinkErrTooMany => 'Troppi tentativi: riprova tra poco.';

  @override
  String get pcLinkErrBusy => 'Un altro telefono è già connesso.';

  @override
  String get pcLinkErrCodeExpired =>
      'Codice scaduto: richiedine uno nuovo a Claude e riconnettiti.';

  @override
  String get pcLinkErrDisconnected => 'Connessione persa.';

  @override
  String get pcLinkReconnecting => 'Connessione persa. Riconnessione in corso…';

  @override
  String get guidePcTitle => 'Cerca con Claude dal tuo PC';

  @override
  String get guidePcBody =>
      'Preparazione — installa il plugin Loop in Claude Code sul tuo computer. Digita queste due righe in Claude Code: /plugin marketplace add devnoyo0123/loop-skill → /plugin install loop@loop. Poi basta dire a Claude «collega il mio telefono»: ti darà l\'indirizzo e un codice di 8 cifre. ① In Impostazioni → Connessione al PC, inserisci quell\'indirizzo e connettiti ② inserisci il codice e sei connesso — da allora si riconnette automaticamente. I diari restano sul telefono: solo query e risultati viaggiano nella tua Wi-Fi.';
}
