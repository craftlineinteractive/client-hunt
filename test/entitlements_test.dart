import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/entitlements/feature_gate.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every gate rule, on both plans.
void main() {
  const FeatureGate free = FeatureGate(freeEntitlements);
  const FeatureGate pro = FeatureGate(proEntitlements);

  group('plan values', () {
    test('Free matches the approved limits', () {
      expect(freeEntitlements.isPro, isFalse);
      expect(freeEntitlements.maxResultsPerSearch, 50);
      expect(freeEntitlements.maxSavedLeads, 50);
      expect(freeEntitlements.freeSearchesPerDay, 5);
      expect(freeEntitlements.allowedSources, <LeadSource>{LeadSource.maps});
      expect(freeEntitlements.deepSearchAllowed, isFalse);
      expect(freeEntitlements.noWebsiteFilterAllowed, isFalse);
      expect(freeEntitlements.adsEnabled, isTrue);
      expect(freeEntitlements.socialProfilesVisible, isFalse);
      expect(freeEntitlements.exportFormats, ExportFormat.values.toSet());
    });

    test('Pro matches the approved limits', () {
      expect(proEntitlements.isPro, isTrue);
      expect(proEntitlements.maxResultsPerSearch, 200);
      expect(proEntitlements.maxSavedLeads, isNull, reason: 'unlimited');
      expect(proEntitlements.freeSearchesPerDay, isNull, reason: 'no limit');
      expect(proEntitlements.allowedSources, <LeadSource>{
        LeadSource.maps,
        LeadSource.instagram,
        LeadSource.linkedin,
        LeadSource.facebook,
        LeadSource.x,
      });
      expect(proEntitlements.deepSearchAllowed, isTrue);
      expect(proEntitlements.noWebsiteFilterAllowed, isTrue);
      expect(proEntitlements.adsEnabled, isFalse);
      expect(proEntitlements.socialProfilesVisible, isTrue);
      expect(proEntitlements.exportFormats, ExportFormat.values.toSet());
    });

    test('web is never a selectable source', () {
      expect(Entitlements.selectableSources, hasLength(5));
      expect(Entitlements.selectableSources, isNot(contains(LeadSource.web)));
      for (final LeadSource source in proEntitlements.allowedSources) {
        expect(Entitlements.selectableSources, contains(source));
      }
    });
  });

  group('sources', () {
    test('Free allows Maps only and locks every social source', () {
      expect(free.canUseSource(LeadSource.maps), isTrue);
      for (final LeadSource source in <LeadSource>[
        LeadSource.instagram,
        LeadSource.linkedin,
        LeadSource.facebook,
        LeadSource.x,
      ]) {
        expect(free.canUseSource(source), isFalse, reason: source.name);
        expect(
          free.reasonForSource(source),
          LockReason.sourceRequiresPro,
          reason: source.name,
        );
      }
      expect(free.reasonForSource(LeadSource.maps), isNull);
    });

    test('Pro allows all five sources', () {
      for (final LeadSource source in Entitlements.selectableSources) {
        expect(pro.canUseSource(source), isTrue, reason: source.name);
        expect(pro.reasonForSource(source), isNull);
      }
    });
  });

  group('social profiles', () {
    test('Free sees the networks but not the handles', () {
      expect(free.canViewSocialProfiles, isFalse);
      expect(free.reasonForSocialProfiles, LockReason.socialProfilesRequirePro);
    });

    test('Pro can read the handles', () {
      expect(pro.canViewSocialProfiles, isTrue);
      expect(pro.reasonForSocialProfiles, isNull);
    });

    test('the flag survives copyWith', () {
      expect(
        freeEntitlements.copyWith(socialProfilesVisible: true),
        isNot(freeEntitlements),
      );
      expect(
        freeEntitlements
            .copyWith(socialProfilesVisible: true)
            .socialProfilesVisible,
        isTrue,
      );
      expect(
        proEntitlements
            .copyWith(socialProfilesVisible: false)
            .socialProfilesVisible,
        isFalse,
      );
    });
  });

  group('deep search and the no-website filter', () {
    test('Free locks both', () {
      expect(free.canUseDeepSearch, isFalse);
      expect(free.canUseNoWebsiteFilter, isFalse);
      expect(
        free.reasonForDepth(SearchDepth.deep),
        LockReason.deepSearchRequiresPro,
      );
      expect(free.reasonForDepth(SearchDepth.fast), isNull);
      expect(
        free.reasonForNoWebsiteFilter,
        LockReason.noWebsiteFilterRequiresPro,
      );
    });

    test('Pro unlocks both', () {
      expect(pro.canUseDeepSearch, isTrue);
      expect(pro.canUseNoWebsiteFilter, isTrue);
      expect(pro.reasonForDepth(SearchDepth.deep), isNull);
      expect(pro.reasonForNoWebsiteFilter, isNull);
    });
  });

  group('max results', () {
    test('Free offers 25/50 unlocked and 100/200 with a lock badge', () {
      expect(free.maxResultsOptions, const <MaxResultsOption>[
        MaxResultsOption(value: 25, isLocked: false),
        MaxResultsOption(value: 50, isLocked: false),
        MaxResultsOption(value: 100, isLocked: true),
        MaxResultsOption(value: 200, isLocked: true),
      ]);
    });

    test('Pro unlocks all four', () {
      expect(
        pro.maxResultsOptions.every(
          (MaxResultsOption option) => !option.isLocked,
        ),
        isTrue,
      );
      expect(pro.maxResultsOptions.map((MaxResultsOption o) => o.value), <int>[
        25,
        50,
        100,
        200,
      ]);
    });

    test('the reason names the cap', () {
      expect(free.isMaxResultsAllowed(50), isTrue);
      expect(free.isMaxResultsAllowed(100), isFalse);
      expect(free.reasonForMaxResults(200), LockReason.maxResultsRequiresPro);
      expect(pro.reasonForMaxResults(200), isNull);
    });
  });

  group('saved leads and searches', () {
    test('Free caps saved leads at 50', () {
      expect(free.canSaveMore(0), isTrue);
      expect(free.canSaveMore(49), isTrue);
      expect(free.canSaveMore(50), isFalse);
      expect(free.reasonForSaving(50), LockReason.savedLeadLimitReached);
      expect(free.remainingSavedSlots(42), 8);
      expect(free.remainingSavedSlots(60), 0);
    });

    test('Pro has no saved-lead cap', () {
      expect(pro.canSaveMore(100000), isTrue);
      expect(pro.remainingSavedSlots(128), isNull);
      expect(pro.reasonForSaving(128), isNull);
    });

    test('Free has five searches a day', () {
      expect(free.canSearchToday(1), isTrue);
      expect(free.canSearchToday(0), isFalse);
      expect(free.reasonForSearching(0), LockReason.dailySearchLimitReached);
    });

    test('Pro has no daily search limit', () {
      expect(pro.canSearchToday(0), isTrue);
      expect(pro.reasonForSearching(0), isNull);
    });
  });

  group('ads and exports', () {
    test('ads are Free-only', () {
      expect(free.showsAds, isTrue);
      expect(pro.showsAds, isFalse);
    });

    test('all four export formats are allowed on both plans', () {
      for (final ExportFormat format in ExportFormat.values) {
        expect(free.canExport(format), isTrue, reason: format.name);
        expect(pro.canExport(format), isTrue, reason: format.name);
      }
    });
  });

  group('reasonForLock', () {
    test('returns null when everything requested is allowed', () {
      expect(
        free.reasonForLock(source: LeadSource.maps, maxResults: 50),
        isNull,
      );
      expect(
        pro.reasonForLock(
          source: LeadSource.instagram,
          depth: SearchDepth.deep,
          maxResults: 200,
          wantsNoWebsiteFilter: true,
          savedCount: 900,
          searchesRemainingToday: 0,
        ),
        isNull,
      );
    });

    test('reports the first blocked control in screen order', () {
      expect(
        free.reasonForLock(
          source: LeadSource.instagram,
          depth: SearchDepth.deep,
          maxResults: 200,
        ),
        LockReason.sourceRequiresPro,
      );
      expect(
        free.reasonForLock(depth: SearchDepth.deep, maxResults: 200),
        LockReason.deepSearchRequiresPro,
      );
      expect(
        free.reasonForLock(maxResults: 200, savedCount: 60),
        LockReason.maxResultsRequiresPro,
      );
      expect(
        free.reasonForLock(wantsNoWebsiteFilter: true),
        LockReason.noWebsiteFilterRequiresPro,
      );
      expect(
        free.reasonForLock(savedCount: 50),
        LockReason.savedLeadLimitReached,
      );
      expect(
        free.reasonForLock(searchesRemainingToday: 0),
        LockReason.dailySearchLimitReached,
      );
    });
  });

  test('Entitlements is a value type', () {
    expect(freeEntitlements, freeEntitlements.copyWith());
    expect(freeEntitlements == proEntitlements, isFalse);
    expect(freeEntitlements.copyWith(isPro: true).isPro, isTrue);
  });
}
