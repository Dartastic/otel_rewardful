// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_rewardful/otel_rewardful.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_rewardful-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('referrals.get records campaign + state + stripe customer', () async {
    await tracedRewardful<String>(
      operation: 'referrals.get',
      invoke: () async => const RewardfulCallResult(
        value: 'ok',
        result: RewardfulResult(
          campaignId: 'camp_1',
          commissionType: 'percent',
          commissionPercent: 20,
          affiliateId: 'aff_1',
          affiliateState: 'active',
          referralId: 'ref_1',
          referralState: 'conversion',
          stripeCustomerId: 'cus_abc',
          couponCode: 'AFF20',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('rewardful referrals.get')!);
    expect(a['rewardful.commission.percent'], 20);
    expect(a['rewardful.referral.state'], 'conversion');
    expect(a['rewardful.stripe.customer_id'], 'cus_abc');
    expect(a['rewardful.coupon.code'], 'AFF20');
  });

  test('payouts.pay records state + amount + paid flag', () async {
    await tracedRewardful<String>(
      operation: 'payouts.pay',
      invoke: () async => const RewardfulCallResult(
        value: 'ok',
        result: RewardfulResult(
          payoutId: 'p_1',
          payoutState: 'paid',
          commissionId: 'com_1',
          commissionAmountCents: 8500,
          commissionPaid: true,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('rewardful payouts.pay')!);
    expect(a['rewardful.payout.state'], 'paid');
    expect(a['rewardful.commission.amount_cents'], 8500);
    expect(a['rewardful.commission.paid'], true);
  });

  test('failed payout sets span error', () async {
    await tracedRewardful<String>(
      operation: 'payouts.pay',
      invoke: () async => const RewardfulCallResult(
        value: 'ok',
        result: RewardfulResult(
          payoutId: 'p_2',
          payoutState: 'failed',
        ),
      ),
    );
    expect(
      spans.findSpanByName('rewardful payouts.pay')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutRewardfulInstrumentationAsync(() async {
      await tracedRewardful<String>(
        operation: 'affiliates.list',
        invoke: () async => const RewardfulCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('rewardful '), isEmpty);
  });
}
