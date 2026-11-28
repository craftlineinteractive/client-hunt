import '../models/models.dart';

/// Why a tag the user typed cannot be added.
///
/// The sheet maps each value to one short sentence; the rule itself lives here so
/// the same limits hold on Saved, in bulk tagging and in any future import.
enum TagError {
  /// Only whitespace was typed.
  empty,

  /// Shorter than [CrmRules.minTagLength] after trimming.
  tooShort,

  /// Longer than [CrmRules.maxTagLength].
  tooLong,

  /// The lead already has [CrmRules.maxTags] tags.
  tooManyTags,

  /// The same tag already exists (case-insensitively).
  duplicate,

  /// Contains something other than letters, numbers, spaces, `-`, `_` or `&`.
  invalidCharacters,
}

/// The limits and checks for the user's own CRM data.
///
/// Tags are free-text labels attached to one lead; lists (on Saved) are named
/// collections a lead belongs to. They are different things with different
/// limits, and nothing here applies to lists.
abstract final class CrmRules {
  const CrmRules._();

  /// Tags a single lead may carry.
  static const int maxTags = 10;

  /// Shortest tag allowed, after trimming.
  static const int minTagLength = 1;

  /// Longest tag allowed, after trimming.
  static const int maxTagLength = 24;

  /// Longest note allowed, in characters.
  static const int maxNoteLength = 2000;

  /// The note field shows its counter from this length up.
  static const int noteCounterThreshold = 1800;

  /// Letters, numbers, spaces, hyphen, underscore and ampersand.
  ///
  /// Deliberately narrow: a tag is a label the user will type again, so emoji
  /// and punctuation create duplicates that look identical.
  static final RegExp allowedCharacters = RegExp(r'^[A-Za-z0-9 _&-]+$');

  /// Trims and collapses runs of whitespace, without changing case.
  static String normalizeTag(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// The first reason [raw] cannot be added to a lead with [existing] tags.
  ///
  /// Comparison is case-insensitive and on the normalized value, so "Hot  lead"
  /// cannot slip past an existing "hot lead".
  static TagError? validateTag(String raw, {required List<String> existing}) {
    final String tag = normalizeTag(raw);
    if (tag.isEmpty) {
      return TagError.empty;
    }
    if (tag.length < minTagLength) {
      return TagError.tooShort;
    }
    if (tag.length > maxTagLength) {
      return TagError.tooLong;
    }
    if (existing.length >= maxTags) {
      return TagError.tooManyTags;
    }
    if (!allowedCharacters.hasMatch(tag)) {
      return TagError.invalidCharacters;
    }
    final String lower = tag.toLowerCase();
    for (final String other in existing) {
      if (normalizeTag(other).toLowerCase() == lower) {
        return TagError.duplicate;
      }
    }
    return null;
  }

  /// True when [lead] carries any private CRM data: a note, a tag, a status
  /// other than New, or a follow-up date.
  ///
  /// Unsaving such a lead deletes it from this device, so the confirmation is
  /// only needed here — a plain bookmark can be removed in one tap.
  static bool hasCrmData(Lead lead) =>
      lead.note.trim().isNotEmpty ||
      lead.tags.isNotEmpty ||
      lead.status != LeadStatus.newLead ||
      lead.reminderAt != null;

  /// The note text a field may hold, truncated to [maxNoteLength].
  static String clampNote(String raw) =>
      raw.length <= maxNoteLength ? raw : raw.substring(0, maxNoteLength);
}
