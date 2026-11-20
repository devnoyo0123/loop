import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/ipv4_input.dart';
import '../services/pc_link.dart';

/// PC 연결 — 맥의 loop-skill 브리지에 붙는 화면. (docs/mcp-bridge-design.md)
/// 맥 주소 입력 → (최초 1회) 8자리 코드 → 연결. 이후 주소 기억·자동 페어링.
class PcLinkScreen extends StatefulWidget {
  const PcLinkScreen({
    super.key,
    required this.controller,
    this.subnetLookup = wifiSubnetPrefix,
  });

  final PcLinkController controller;

  /// 빈 칸을 폰 Wi-Fi 서브넷("192.168.35.")으로 미리 채울 때 쓴다.
  final SubnetPrefixLookup subnetLookup;

  static Future<void> show(
    BuildContext context, {
    required PcLinkController controller,
  }) => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => PcLinkScreen(controller: controller)),
  );

  @override
  State<PcLinkScreen> createState() => _PcLinkScreenState();
}

class _PcLinkScreenState extends State<PcLinkScreen> {
  PcLinkController get _c => widget.controller;

  late final TextEditingController _host;
  final TextEditingController _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: _c.host);
    _c.addListener(_changed);
    if (_host.text.isEmpty) _prefillSubnet();
  }

  /// 저장된 주소가 없으면 맥도 같은 공유기에 있을 테니 앞 세 자리를 채워 둔다.
  Future<void> _prefillSubnet() async {
    final prefix = await widget.subnetLookup();
    if (!mounted || prefix == null || _host.text.isNotEmpty) return;
    _host.value = TextEditingValue(
      text: prefix,
      selection: TextSelection.collapsed(offset: prefix.length),
    );
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    _host.dispose();
    _code.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pcLinkTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LoopSpacing.l),
          children: [
            Text(
              l10n.pcLinkIntro,
              style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
            ),
            const SizedBox(height: LoopSpacing.l),
            if (_c.status == PcLinkStatus.connected)
              _connectedCard(l10n)
            else ...[
              _hostField(l10n),
              const SizedBox(height: LoopSpacing.m),
              _connectButton(l10n),
              if (_c.status == PcLinkStatus.waitingCode) ...[
                const SizedBox(height: LoopSpacing.l),
                _codeCard(l10n),
              ],
              if (_c.reconnecting) ...[
                const SizedBox(height: LoopSpacing.m),
                _reconnectingBanner(l10n),
              ] else if (_c.lastError != null) ...[
                const SizedBox(height: LoopSpacing.m),
                _errorBanner(l10n),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _hostField(AppLocalizations l10n) {
    final busy = _c.status == PcLinkStatus.connecting ||
        _c.status == PcLinkStatus.pairing;
    return TextField(
      key: const ValueKey('pclink-host-field'),
      controller: _host,
      enabled: !busy,
      // 숫자 키패드 + "." — 점은 짧은 옥텟을 끝낼 때만 필요하다.
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [Ipv4InputFormatter()],
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: l10n.pcLinkHostLabel,
        hintText: l10n.pcLinkHostHint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }

  Widget _connectButton(AppLocalizations l10n) {
    final connecting = _c.status == PcLinkStatus.connecting ||
        _c.status == PcLinkStatus.pairing;
    return FilledButton.icon(
      key: const ValueKey('pclink-connect-btn'),
      onPressed: connecting ? null : () => _c.connect(host: _host.text),
      icon: connecting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cable, size: 18),
      label: Text(connecting ? l10n.pcLinkConnecting : l10n.pcLinkConnect),
    );
  }

  /// 코드 입력 — Claude에게 `pairing_code`를 요청해 받은 8자리.
  Widget _codeCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(LoopSpacing.l),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoopColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.pcLinkCodeTitle, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: LoopSpacing.s),
          Text(
            l10n.pcLinkCodeBody,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: LoopSpacing.m),
          Row(children: [
            Expanded(
              child: TextField(
                key: const ValueKey('pclink-code-field'),
                controller: _code,
                enabled: _c.status == PcLinkStatus.waitingCode,
                keyboardType: TextInputType.number,
                maxLength: 8,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: l10n.pcLinkCodeHint,
                  counterText: '',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(width: LoopSpacing.m),
            FilledButton(
              key: const ValueKey('pclink-code-submit'),
              onPressed: _c.status == PcLinkStatus.waitingCode
                  ? () => _c.submitCode(_code.text)
                  : null,
              child: Text(l10n.pcLinkCodeSubmit),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _connectedCard(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('pclink-connected-card'),
      padding: const EdgeInsets.all(LoopSpacing.l),
      decoration: BoxDecoration(
        color: LoopColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoopColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.check_circle, size: 20, color: LoopColors.mint),
            const SizedBox(width: LoopSpacing.s),
            Expanded(
              child: Text(
                l10n.pcLinkConnectedTitle,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ]),
          const SizedBox(height: LoopSpacing.s),
          Text(
            l10n.pcLinkConnectedBody,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: LoopSpacing.m),
          _kv(l10n.pcLinkHostLabel, _c.host),
          _kv(l10n.pcLinkQueries, '${_c.queryCount}'),
          const SizedBox(height: LoopSpacing.m),
          OutlinedButton.icon(
            key: const ValueKey('pclink-disconnect-btn'),
            onPressed: _c.disconnect,
            icon: const Icon(Icons.link_off, size: 16),
            label: Text(l10n.pcLinkDisconnect),
            style: OutlinedButton.styleFrom(
              foregroundColor: LoopColors.text,
              side: const BorderSide(color: LoopColors.line),
              visualDensity: VisualDensity.compact,
            ),
          ),
          if (_c.paired)
            TextButton(
              key: const ValueKey('pclink-unpair-btn'),
              onPressed: _c.unpair,
              child: Text(
                l10n.pcLinkUnpair,
                style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: LoopSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: LoopColors.text,
            ),
          ),
        ),
      ],
    ),
  );

  /// 끊긴 뒤 자동 재연결을 기다리는 중 — 오류가 아니라 진행 상태로 보인다.
  /// "연결" 버튼을 누르면 기다리지 않고 바로 시도한다.
  Widget _reconnectingBanner(AppLocalizations l10n) {
    return Row(
      key: const ValueKey('pclink-reconnecting-banner'),
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: Text(
            l10n.pcLinkReconnecting,
            style: const TextStyle(color: LoopColors.textDim, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(AppLocalizations l10n) {
    return Row(
      key: const ValueKey('pclink-error-banner'),
      children: [
        const Icon(Icons.error_outline, size: 16, color: LoopColors.danger),
        const SizedBox(width: LoopSpacing.s),
        Expanded(
          child: Text(
            _errorText(l10n, _c.lastError!),
            style: const TextStyle(color: LoopColors.danger, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _errorText(AppLocalizations l10n, PcLinkError e) => switch (e) {
    PcLinkError.refused => l10n.pcLinkErrRefused,
    PcLinkError.timeout => l10n.pcLinkErrTimeout,
    PcLinkError.badHost => l10n.pcLinkErrBadHost,
    PcLinkError.codeWrong => l10n.pcLinkErrCodeWrong(_c.attemptsLeft),
    PcLinkError.tooMany => l10n.pcLinkErrTooMany,
    PcLinkError.busy => l10n.pcLinkErrBusy,
    PcLinkError.codeExpired => l10n.pcLinkErrCodeExpired,
    PcLinkError.disconnected => l10n.pcLinkErrDisconnected,
  };
}
