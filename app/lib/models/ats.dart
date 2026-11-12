import 'opportunity.dart';
import 'user.dart';

/// Prototype ATS scoring. Not a real parser: a transparent heuristic over the saved resume so the
/// score on Home, Profile and every job reacts to what the student adds.
class AtsFix {
  final String title;
  final int points;
  final bool done;
  const AtsFix(this.title, this.points, this.done);
}

extension AtsScore on User {
  List<AtsFix> get atsFixes {
    final r = resume;
    final hasSummary = (r?.summary ?? '').trim().length > 20;
    final skills = r?.skills.length ?? 0;
    final hasExp = (r?.workExperience.isNotEmpty ?? false) || (r?.projects.isNotEmpty ?? false);
    final quantified = (r?.workExperience ?? const []).any((w) => RegExp(r'\d').hasMatch(w.description)) || (r?.achievements.isNotEmpty ?? false);
    return [
      AtsFix('Add a 2-line summary', 6, hasSummary),
      AtsFix('Add at least 6 skills', 5, skills >= 6),
      AtsFix('Add experience or a project', 6, hasExp),
      AtsFix('Quantify two achievements', 4, quantified),
    ];
  }

  /// 0..100. A missing resume scores 0 so Home can nudge the student to build one.
  int get atsScore {
    if (resume == null) return 0;
    var s = 62;
    for (final f in atsFixes) {
      if (f.done) s += f.points;
    }
    final edu = resume!.education.isNotEmpty ? 5 : 0;
    return (s + edu).clamp(0, 100);
  }

  int get atsPotential => (atsScore + atsFixes.where((f) => !f.done).fold<int>(0, (a, f) => a + f.points)).clamp(0, 100);
}

extension AtsFit on Opportunity {
  /// How well the student's resume lines up with this role, 0..100.
  int atsFitFor(User? user) {
    if (user == null || user.resume == null) return 0;
    final base = user.atsScore;
    final req = requirements.join(' ').toLowerCase();
    final skills = user.resume!.skills;
    final hits = skills.where((s) => req.contains(s.toLowerCase())).length;
    return (base - 12 + hits * 4).clamp(0, 99);
  }

  /// Keywords the role asks for that the resume does not mention yet.
  List<String> missingKeywordsFor(User? user) {
    final have = (user?.resume?.skills ?? const <String>[]).map((s) => s.toLowerCase()).toSet();
    final words = <String>{};
    for (final r in requirements) {
      for (final w in r.split(RegExp(r'[,/;·]| and '))) {
        final t = w.trim();
        if (t.length > 2 && t.length < 24 && t.split(' ').length <= 3) words.add(t);
      }
    }
    return words.where((w) => !have.contains(w.toLowerCase())).take(3).toList();
  }
}
