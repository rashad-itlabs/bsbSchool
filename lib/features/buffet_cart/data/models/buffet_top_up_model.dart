import 'dart:convert';

import '../../domain/entities/buffet_top_up.dart';

class BuffetTopUpModel extends BuffetTopUp {
  const BuffetTopUpModel({
    super.purpose,
    super.amount,
    super.date,
    super.receipt,
  });

  /// Matches one entry of the `incoming` array from `GET /getBuffetCart`:
  /// ```json
  /// { "purpose": "Balans artımı", "ampunt": "5.00",
  ///   "created_balance": "2026-09-16 23:44:17", "payload": "{…}" }
  /// ```
  ///
  /// `ampunt` is the API's own spelling; `amount` is read too so a fixed
  /// backend keeps working.
  factory BuffetTopUpModel.fromJson(Map<String, dynamic> json) =>
      BuffetTopUpModel(
        purpose: _asString(json['purpose']),
        amount: _asNum(json['ampunt']) ?? _asNum(json['amount']),
        date: _asDate(json['created_balance']) ?? _asDate(json['created_at']),
        receipt: _receipt(json['payload']),
      );

  /// The payload arrives as a JSON *string*; a bad or absent one leaves the
  /// row without a receipt instead of failing the whole response.
  static TopUpReceiptModel? _receipt(dynamic payload) {
    final map = _asMap(payload);
    if (map == null) return null;
    final receipt = TopUpReceiptModel.fromJson(map);
    return receipt.hasDetails ? receipt : null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    final text = _asString(value);
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  static num? _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}

class TopUpReceiptModel extends TopUpReceipt {
  const TopUpReceiptModel({
    super.reference,
    super.rrn,
    super.approval,
    super.pan,
    super.issuer,
    super.system,
    super.method,
    super.amount,
    super.fee,
    super.currency,
    super.status,
    super.code,
    super.message,
    super.datetime,
  });

  /// Matches the gateway's `payload` block. Only the fields a parent or a bank
  /// would ask about are kept — `extra`, `offset`, `biller` and `refund` are
  /// the gateway's own bookkeeping and never reach the screen.
  factory TopUpReceiptModel.fromJson(Map<String, dynamic> json) =>
      TopUpReceiptModel(
        reference: _asString(json['reference']),
        rrn: _asString(json['rrn']),
        approval: _asString(json['approval']),
        pan: _asString(json['pan']),
        issuer: _asString(json['issuer']),
        system: _asString(json['system']),
        method: _asString(json['method']),
        amount: _asNum(json['amount']),
        fee: _asNum(json['fee']),
        currency: _asString(json['currency']),
        status: _asString(json['status']),
        code: _asInt(json['code']),
        message: _asString(json['message']),
        datetime: _asDate(json['datetime']),
      );

  static int? _asInt(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  static num? _asNum(dynamic value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '');

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _asDate(dynamic value) {
    final text = _asString(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
