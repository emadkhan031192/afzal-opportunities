import 'package:afzal_opportunities/core/l10n/app_localizations.dart';
import 'package:afzal_opportunities/core/utils/url_utils.dart';
import 'package:afzal_opportunities/models/advertisement.dart';
import 'package:afzal_opportunities/services/advertisement_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Google Play "Misleading Claims" fix: every advertisement must carry an
/// official source link, the details screen must say plainly that the app
/// is not a government entity, and a listing without a source link must
/// show a visible warning instead of silently hiding the gap.
///
/// The details screen shows the missing-source notice exactly when the
/// advertisement has no safe source URL, i.e. when
/// `isSafeHttpUrl(ad.sourceUrl)` is false.
///
/// v1.4.1+9 goes further: the public feed itself hides advertisements
/// without a usable official source link ([Advertisement.hasSourceUrl] /
/// [filterSourcedAds]), so the store description's "every government
/// listing links to its original official source" is true at all times.
/// Unsourced advertisements stay visible in the admin panel under
/// "Needs source link" until an editor adds the source.
void main() {
  group('missing-source notice condition (isSafeHttpUrl)', () {
    test('null, empty and blank source URLs count as missing', () {
      expect(isSafeHttpUrl(null), isFalse);
      expect(isSafeHttpUrl(''), isFalse);
      expect(isSafeHttpUrl('   '), isFalse);
    });

    test('malformed and non-web URLs count as missing', () {
      expect(isSafeHttpUrl('not a url'), isFalse);
      expect(isSafeHttpUrl('javascript:alert(1)'), isFalse);
      expect(isSafeHttpUrl('ftp://example.com/jobs'), isFalse);
      expect(isSafeHttpUrl('https://'), isFalse);
    });

    test('http/https URLs with a host count as present', () {
      expect(isSafeHttpUrl('https://kppsc.gov.pk'), isTrue);
      expect(isSafeHttpUrl('http://healthkp.gov.pk/jobs'), isTrue);
      expect(isSafeHttpUrl('  https://njp.gov.pk  '), isTrue);
    });
  });

  group('public feed source gate (v1.4.1+9)', () {
    Advertisement makeAd(String id, {String? sourceUrl}) {
      return Advertisement(
        id: id,
        title: 'Title $id',
        organization: 'Org',
        category: 'jobs',
        description: 'Description',
        status: 'published',
        sourceUrl: sourceUrl,
      );
    }

    test('hasSourceUrl accepts http/https URLs with a host', () {
      expect(
        makeAd('a', sourceUrl: 'https://kppsc.gov.pk').hasSourceUrl,
        isTrue,
      );
      expect(
        makeAd('b', sourceUrl: 'http://healthkp.gov.pk/jobs').hasSourceUrl,
        isTrue,
      );
      expect(
        makeAd('c', sourceUrl: '  https://etea.edu.pk  ').hasSourceUrl,
        isTrue,
      );
    });

    test('hasSourceUrl rejects missing, blank and non-web sources', () {
      expect(makeAd('a').hasSourceUrl, isFalse);
      expect(makeAd('b', sourceUrl: '   ').hasSourceUrl, isFalse);
      expect(makeAd('c', sourceUrl: 'not a url').hasSourceUrl, isFalse);
      expect(makeAd('d', sourceUrl: 'https://').hasSourceUrl, isFalse);
      expect(
        makeAd('e', sourceUrl: 'javascript:alert(1)').hasSourceUrl,
        isFalse,
      );
      expect(makeAd('f', sourceUrl: 'tel:+923001234567').hasSourceUrl, isFalse);
    });

    test('filterSourcedAds keeps only sourced ads, in order', () {
      final ads = [
        makeAd('sourced-1', sourceUrl: 'https://kppsc.gov.pk'),
        makeAd('unsourced'),
        makeAd('sourced-2', sourceUrl: 'https://etea.edu.pk'),
        makeAd('broken', sourceUrl: 'not a url'),
      ];
      expect(filterSourcedAds(ads).map((a) => a.id), [
        'sourced-1',
        'sourced-2',
      ]);
    });

    test('filterSourcedAds does not mutate the input list', () {
      final ads = [makeAd('a', sourceUrl: 'https://kppsc.gov.pk'), makeAd('b')];
      filterSourcedAds(ads);
      expect(ads.map((a) => a.id), ['a', 'b']);
    });
  });

  group('not-a-government-entity disclaimer strings', () {
    test('English strings exist and name the policy point', () {
      final s = AppLocalizations(const Locale('en'));
      expect(s.disclaimerNotGovernment, contains('not a government entity'));
      expect(s.disclaimerNotGovernment, contains('not affiliated'));
      expect(s.disclaimerVerifyDetails, contains('verify details'));
      expect(s.disclaimerVerifyDetails, contains('official source'));
      expect(s.missingSourceWarning, contains('No official source link'));
    });

    test('Urdu strings exist and are real translations, not fallbacks', () {
      final en = AppLocalizations(const Locale('en'));
      final ur = AppLocalizations(const Locale('ur'));
      expect(ur.disclaimerNotGovernment, contains('سرکاری ادارہ نہیں'));
      expect(ur.disclaimerVerifyDetails, contains('سرکاری ماخذ'));
      expect(ur.missingSourceWarning, contains('سرکاری ماخذ لنک'));
      // Guard against a missing Urdu key silently falling back to English.
      expect(ur.disclaimerNotGovernment, isNot(en.disclaimerNotGovernment));
      expect(ur.disclaimerVerifyDetails, isNot(en.disclaimerVerifyDetails));
      expect(ur.missingSourceWarning, isNot(en.missingSourceWarning));
    });
  });
}
