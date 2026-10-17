import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loop/l10n/generated/app_localizations.dart';

/// 6개 언어(ko/en/ja/zh/es/vi)가 전부 생성·해석되는지 검증.
void main() {
  test('supportedLocales에 6개 언어가 있다', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'ko', 'en', 'ja', 'zh', 'es', 'vi'},
    );
  });

  AppLocalizations lookup(String code) =>
      lookupAppLocalizations(Locale(code));

  test('언어별 핵심 문자열 — 검색 힌트', () {
    expect(lookup('ko').searchHint, '내용·장소 검색');
    expect(lookup('en').searchHint, 'Search content & places');
    expect(lookup('ja').searchHint, '内容・場所を検索');
    expect(lookup('zh').searchHint, '搜索内容、地点');
    expect(lookup('es').searchHint, 'Buscar contenido y lugares');
    expect(lookup('vi').searchHint, 'Tìm nội dung, địa điểm');
  });

  test('플레이스홀더 보간이 언어별로 동작 — ruleDaily', () {
    expect(lookup('ko').ruleDaily('09:00'), '매일 09:00');
    expect(lookup('ja').ruleDaily('09:00'), '毎日 09:00');
    expect(lookup('zh').ruleDaily('09:00'), '每天 09:00');
    expect(lookup('es').ruleDaily('09:00'), 'Cada día a las 09:00');
    expect(lookup('vi').ruleDaily('09:00'), 'Hàng ngày lúc 09:00');
  });

  test('zh-CN처럼 지역 코드가 붙어도 기본 zh로 해석된다', () {
    final l = lookupAppLocalizations(const Locale('zh', 'CN'));
    expect(l.sortRelevance, '按相关度');
  });
}
