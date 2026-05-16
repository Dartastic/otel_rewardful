// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_rewardful_suppression.dart';

const _tracerName = 'dartastic_otel_libs_rewardful';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class RewardfulResult {
  const RewardfulResult({
    this.entityKind,
    this.entityId,
    this.campaignId,
    this.commissionType,
    this.commissionPercent,
    this.affiliateId,
    this.affiliateState,
    this.referralId,
    this.referralState,
    this.stripeCustomerId,
    this.commissionId,
    this.commissionAmountCents,
    this.commissionPaid,
    this.payoutId,
    this.payoutState,
    this.couponCode,
    this.statusCode,
  });

  /// `campaign` / `affiliate` / `referral` / `commission` /
  /// `payout` / `coupon` / `link` / `affiliate_link` / `tracking`.
  final String? entityKind;

  final String? entityId;

  final String? campaignId;

  /// `percent` / `flat`.
  final String? commissionType;

  /// 0-100 (only present when commission_type=percent).
  final int? commissionPercent;

  final String? affiliateId;

  /// `active` / `disabled`.
  final String? affiliateState;

  final String? referralId;

  /// `lead` / `trial` / `conversion` / `customer` — referral funnel
  /// stage.
  final String? referralState;

  /// Stripe customer the referral converted into.
  final String? stripeCustomerId;

  final String? commissionId;
  final int? commissionAmountCents;

  /// `true` when Rewardful marked the commission paid.
  final bool? commissionPaid;

  final String? payoutId;

  /// `pending` / `paid` / `cancelled` / `failed`.
  final String? payoutState;

  /// Affiliate-specific coupon code (Stripe Coupon).
  final String? couponCode;

  final int? statusCode;
}

class RewardfulCallResult<T> {
  const RewardfulCallResult({required this.value, this.result});
  final T value;
  final RewardfulResult? result;
}

/// Wraps a Rewardful API call in a CLIENT span. [operation] is one
/// of `campaigns.list`, `campaigns.create`, `affiliates.list`,
/// `affiliates.create`, `affiliates.update`, `referrals.list`,
/// `referrals.get`, `commissions.list`, `commissions.update`,
/// `payouts.list`, `payouts.pay`, `coupons.list`,
/// `coupons.create`, `links.create`.
Future<T> tracedRewardful<T>({
  required String operation,
  required Future<RewardfulCallResult<T>> Function() invoke,
}) async {
  if (rewardfulInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'rewardful',
    'rpc.method': operation,
    'rewardful.operation': operation,
  };

  final span = _tracer().startSpan(
    'rewardful $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.entityKind != null) {
        extras.add(OTel.attributeString(
          'rewardful.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.entityId != null) {
        extras.add(OTel.attributeString(
          'rewardful.entity.id',
          r.result!.entityId!,
        ));
      }
      if (r.result!.campaignId != null) {
        extras.add(OTel.attributeString(
          'rewardful.campaign.id',
          r.result!.campaignId!,
        ));
      }
      if (r.result!.commissionType != null) {
        extras.add(OTel.attributeString(
          'rewardful.commission.type',
          r.result!.commissionType!,
        ));
      }
      if (r.result!.commissionPercent != null) {
        extras.add(OTel.attributeInt(
          'rewardful.commission.percent',
          r.result!.commissionPercent!,
        ));
      }
      if (r.result!.affiliateId != null) {
        extras.add(OTel.attributeString(
          'rewardful.affiliate.id',
          r.result!.affiliateId!,
        ));
      }
      if (r.result!.affiliateState != null) {
        extras.add(OTel.attributeString(
          'rewardful.affiliate.state',
          r.result!.affiliateState!,
        ));
      }
      if (r.result!.referralId != null) {
        extras.add(OTel.attributeString(
          'rewardful.referral.id',
          r.result!.referralId!,
        ));
      }
      if (r.result!.referralState != null) {
        extras.add(OTel.attributeString(
          'rewardful.referral.state',
          r.result!.referralState!,
        ));
      }
      if (r.result!.stripeCustomerId != null) {
        extras.add(OTel.attributeString(
          'rewardful.stripe.customer_id',
          r.result!.stripeCustomerId!,
        ));
      }
      if (r.result!.commissionId != null) {
        extras.add(OTel.attributeString(
          'rewardful.commission.id',
          r.result!.commissionId!,
        ));
      }
      if (r.result!.commissionAmountCents != null) {
        extras.add(OTel.attributeInt(
          'rewardful.commission.amount_cents',
          r.result!.commissionAmountCents!,
        ));
      }
      if (r.result!.commissionPaid != null) {
        extras.add(OTel.attributeBool(
          'rewardful.commission.paid',
          r.result!.commissionPaid!,
        ));
      }
      if (r.result!.payoutId != null) {
        extras.add(OTel.attributeString(
          'rewardful.payout.id',
          r.result!.payoutId!,
        ));
      }
      if (r.result!.payoutState != null) {
        extras.add(OTel.attributeString(
          'rewardful.payout.state',
          r.result!.payoutState!,
        ));
        if (r.result!.payoutState == 'failed') {
          span.setStatus(SpanStatusCode.Error, 'Rewardful payout failed');
        }
      }
      if (r.result!.couponCode != null) {
        extras.add(OTel.attributeString(
          'rewardful.coupon.code',
          r.result!.couponCode!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Rewardful HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
