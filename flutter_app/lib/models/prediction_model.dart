
import 'package:flutter/material.dart';

class PredictionResponse {
  final bool ok;
  final String? error;
  final String? inputUrl;
  final String? normalizedUrl;
  final PredictionResult? result;
  final String? model;

  PredictionResponse({
    required this.ok,
    this.error,
    this.inputUrl,
    this.normalizedUrl,
    this.result,
    this.model,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      ok: json['ok'] ?? false,
      error: json['error'],
      inputUrl: json['input_url'],
      normalizedUrl: json['normalized_url'],
      result: json['result'] != null ? PredictionResult.fromJson(json['result']) : null,
      model: json['model'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'error': error,
      'input_url': inputUrl,
      'normalized_url': normalizedUrl,
      'result': result?.toJson(),
      'model': model,
    };
  }
}

class PredictionResult {
  final String badge;
  final String label;
  final String confidence;
  final String riskLevel;
  final String? explanation;
  final String? ruleTrigger;
  final List<String>? recommendations;
  final Map<String, dynamic>? details;

  PredictionResult({
    required this.badge,
    required this.label,
    required this.confidence,
    required this.riskLevel,
    this.explanation,
    this.ruleTrigger,
    this.recommendations,
    this.details,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      badge: json['badge'] ?? '',
      label: json['label'] ?? '',
      confidence: json['confidence'] ?? '',
      riskLevel: json['risk_level'] ?? '',
      explanation: json['explanation'],
      ruleTrigger: json['rule_trigger'],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      details: json['details'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge,
      'label': label,
      'confidence': confidence,
      'risk_level': riskLevel,
      'explanation': explanation,
      'rule_trigger': ruleTrigger,
      'recommendations': recommendations,
      'details': details,
    };
  }

  bool get isPhishing => label.toLowerCase() == 'phishing';
  bool get isLegitimate => label.toLowerCase() == 'legitimate';
  bool get isUncertain => label.toLowerCase() == 'uncertain';
  bool get isPaymentPayload {
    final lowerLabel = label.toLowerCase();
    final lowerBadge = badge.toLowerCase();
    return lowerLabel == 'payment qr payload' || lowerBadge.contains('payment qr');
  }

  Color get badgeColor {
    if (isPhishing) return const Color(0xFFFF6978);
    if (isPaymentPayload) return const Color(0xFF8FE7FF);
    if (isUncertain) return const Color(0xFFFFD26F);
    return const Color(0xFF63F0A3);
  }

  Color get riskColor {
    final risk = riskLevel.toLowerCase();
    if (risk.contains('verify')) {
      return const Color(0xFF8FE7FF);
    }
    if (risk.contains('manual') || risk.contains('review')) {
      return const Color(0xFFFFD26F);
    }
    if (risk.contains('high')) return const Color(0xFFFF6978);
    if (risk.contains('medium')) return const Color(0xFFFFD26F);
    return const Color(0xFF63F0A3);
  }
}
