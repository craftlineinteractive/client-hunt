import 'package:flutter/foundation.dart';

import 'phone_kind.dart';
import 'validation_status.dart';

/// A single way to reach a business, with its provenance and trust level.
///
/// This is the shared shape for phones and emails; [PhoneContact] and
/// [EmailContact] add the type-specific detail. Every point records **where it
/// was found** ([foundOnUrl], [foundAt]) and **how sure the engine is**
/// ([confidence], [status]) so the UI can be honest and the engine can rank
/// contacts later.
@immutable
class ContactPoint {
  const ContactPoint({
    required this.value,
    this.typeLabel = 'Contact',
    this.status = ValidationStatus.unchecked,
    this.confidence = 0,
    this.foundOnUrl,
    this.foundAt,
    this.isPrimary = false,
  }) : assert(
         confidence >= 0 && confidence <= 1,
         'Confidence is a 0..1 fraction',
       );

  /// The raw contact value (a phone string or an email address).
  final String value;

  /// Short label for the UI ("Phone", "Mobile", "Email", "Work email").
  final String typeLabel;

  /// Validation state; drives the icon plus label shown beside the value.
  final ValidationStatus status;

  /// Engine confidence, 0 to 1.
  final double confidence;

  /// The public page this value was found on, if any.
  final String? foundOnUrl;

  /// When the value was found.
  final DateTime? foundAt;

  /// Whether this is the lead's preferred contact of its type.
  final bool isPrimary;

  /// Copy with selected fields replaced; omitted fields keep their value.
  ContactPoint copyWith({
    String? value,
    String? typeLabel,
    ValidationStatus? status,
    double? confidence,
    String? foundOnUrl,
    DateTime? foundAt,
    bool? isPrimary,
  }) {
    return ContactPoint(
      value: value ?? this.value,
      typeLabel: typeLabel ?? this.typeLabel,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      foundOnUrl: foundOnUrl ?? this.foundOnUrl,
      foundAt: foundAt ?? this.foundAt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContactPoint &&
            other.runtimeType == runtimeType &&
            other.value == value &&
            other.typeLabel == typeLabel &&
            other.status == status &&
            other.confidence == confidence &&
            other.foundOnUrl == foundOnUrl &&
            other.foundAt == foundAt &&
            other.isPrimary == isPrimary;
  }

  @override
  int get hashCode => Object.hash(
    value,
    typeLabel,
    status,
    confidence,
    foundOnUrl,
    foundAt,
    isPrimary,
  );

  @override
  String toString() =>
      'ContactPoint($typeLabel: $value, status: ${status.name})';
}

/// A phone number with its line type.
///
/// [PhoneKind] decides the row label on lead detail and whether a WhatsApp action
/// is plausible. Phone numbers are stored as extracted text; normalizing to E.164
/// is the engine's job (prompt D), so the UI always renders what was found.
@immutable
class PhoneContact extends ContactPoint {
  const PhoneContact({
    required super.value,
    this.kind = PhoneKind.unknown,
    super.typeLabel = 'Phone',
    super.status,
    super.confidence,
    super.foundOnUrl,
    super.foundAt,
    super.isPrimary,
  });

  /// Mobile, landline, toll-free or unknown.
  final PhoneKind kind;

  @override
  PhoneContact copyWith({
    String? value,
    PhoneKind? kind,
    String? typeLabel,
    ValidationStatus? status,
    double? confidence,
    String? foundOnUrl,
    DateTime? foundAt,
    bool? isPrimary,
  }) {
    return PhoneContact(
      value: value ?? this.value,
      kind: kind ?? this.kind,
      typeLabel: typeLabel ?? this.typeLabel,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      foundOnUrl: foundOnUrl ?? this.foundOnUrl,
      foundAt: foundAt ?? this.foundAt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PhoneContact && super == other && other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, kind);

  @override
  String toString() => 'PhoneContact($value, ${kind.name})';
}

/// An email address with deliverability and ownership flags.
///
/// These four booleans are what make an extracted address trustworthy:
/// role addresses (`info@`) are still useful but less personal, disposable
/// domains are junk, a missing MX record means mail will bounce, and an address
/// on the business's own domain is stronger evidence than a free provider.
@immutable
class EmailContact extends ContactPoint {
  const EmailContact({
    required super.value,
    this.isRoleBased = false,
    this.isDisposable = false,
    this.domainHasMx = false,
    this.matchesWebsiteDomain = false,
    super.typeLabel = 'Email',
    super.status,
    super.confidence,
    super.foundOnUrl,
    super.foundAt,
    super.isPrimary,
  });

  /// True for shared inboxes (`info@`, `sales@`, `contact@`).
  final bool isRoleBased;

  /// True when the domain is a known throwaway provider.
  final bool isDisposable;

  /// True when the domain publishes an MX record.
  final bool domainHasMx;

  /// True when the address uses the lead's own website domain.
  final bool matchesWebsiteDomain;

  @override
  EmailContact copyWith({
    String? value,
    bool? isRoleBased,
    bool? isDisposable,
    bool? domainHasMx,
    bool? matchesWebsiteDomain,
    String? typeLabel,
    ValidationStatus? status,
    double? confidence,
    String? foundOnUrl,
    DateTime? foundAt,
    bool? isPrimary,
  }) {
    return EmailContact(
      value: value ?? this.value,
      isRoleBased: isRoleBased ?? this.isRoleBased,
      isDisposable: isDisposable ?? this.isDisposable,
      domainHasMx: domainHasMx ?? this.domainHasMx,
      matchesWebsiteDomain: matchesWebsiteDomain ?? this.matchesWebsiteDomain,
      typeLabel: typeLabel ?? this.typeLabel,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      foundOnUrl: foundOnUrl ?? this.foundOnUrl,
      foundAt: foundAt ?? this.foundAt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EmailContact &&
            super == other &&
            other.isRoleBased == isRoleBased &&
            other.isDisposable == isDisposable &&
            other.domainHasMx == domainHasMx &&
            other.matchesWebsiteDomain == matchesWebsiteDomain;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    isRoleBased,
    isDisposable,
    domainHasMx,
    matchesWebsiteDomain,
  );

  @override
  String toString() => 'EmailContact($value, role: $isRoleBased)';
}
