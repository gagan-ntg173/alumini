// lib/services/match_service.dart
// Two-way matching: one person's OFFERS meet the other person's SEEKS.
// Works for every role, so one function serves the whole app.

enum UserRole { student, faculty, alumni, founder, recruiter, institution }

class Profile {
  final String id;
  final String name;
  final UserRole role;
  final String domain; // e.g. "Data Science"
  final String college;
  final List<String> offers; // expertise or opportunities you give, e.g. "ML", "internship"
  final List<String> seeks; // what you are looking for, e.g. "mentor", "ML", "intern"

  const Profile({
    required this.id,
    required this.name,
    required this.role,
    this.domain = '',
    this.college = '',
    this.offers = const [],
    this.seeks = const [],
  });

  /// Build from a Firestore document: Profile.fromMap(doc.id, doc.data()!)
  factory Profile.fromMap(String id, Map<String, dynamic> m) => Profile(
        id: id,
        name: m['name'] ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == m['role'],
          orElse: () => UserRole.student,
        ),
        domain: m['domain'] ?? '',
        college: m['college'] ?? '',
        offers: List<String>.from(m['offers'] ?? const []),
        seeks: List<String>.from(m['seeks'] ?? const []),
      );
}

class MatchResult {
  final Profile profile;
  final int score; // 0-100, shown as "92% match"
  final List<String> sharedTags; // shown as chips on the card

  const MatchResult(this.profile, this.score, this.sharedTags);
}

class MatchService {
  // Weights add up to 100. Tune these during the hackathon.
  static const double wTheyFitMe = 40; // their offers cover what I seek
  static const double wIFitThem = 40; // my offers cover what they seek
  static const double wDomain = 10;
  static const double wCampus = 10;

  static String _n(String s) => s.trim().toLowerCase();

  /// Share of [needs] that [gives] covers (0.0 to 1.0).
  static double _coverage(Set<String> needs, Set<String> gives) =>
      needs.isEmpty ? 0.0 : needs.intersection(gives).length / needs.length;

  /// Score [other] from [me]'s point of view.
  static MatchResult score(Profile me, Profile other) {
    final mySeeks = me.seeks.map(_n).toSet();
    final myOffers = me.offers.map(_n).toSet();
    final theirSeeks = other.seeks.map(_n).toSet();
    final theirOffers = other.offers.map(_n).toSet();

    final theyFitMe = _coverage(mySeeks, theirOffers);
    final iFitThem = _coverage(theirSeeks, myOffers);

    final domainFit =
        me.domain.isNotEmpty && _n(me.domain) == _n(other.domain) ? 1.0 : 0.0;
    final campusFit =
        me.college.isNotEmpty && _n(me.college) == _n(other.college) ? 1.0 : 0.0;

    final total = theyFitMe * wTheyFitMe +
        iFitThem * wIFitThem +
        domainFit * wDomain +
        campusFit * wCampus;

    // Tags to show on the card (original spelling, no duplicates)
    final shared = <String>{
      ...other.offers.where((t) => mySeeks.contains(_n(t))),
      ...other.seeks.where((t) => myOffers.contains(_n(t))),
    }.toList();

    return MatchResult(other, total.round(), shared);
  }

  /// Rank everyone for [me], best match first.
  /// [alreadySwiped] holds ids already seen; [roleFilter] limits to certain roles.
  static List<MatchResult> rank(
    Profile me,
    List<Profile> others, {
    Set<String> alreadySwiped = const {},
    Set<UserRole>? roleFilter,
  }) {
    final results = others
        .where((o) => o.id != me.id)
        .where((o) => !alreadySwiped.contains(o.id))
        .where((o) => roleFilter == null || roleFilter.contains(o.role))
        .map((o) => score(me, o))
        .toList();
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
