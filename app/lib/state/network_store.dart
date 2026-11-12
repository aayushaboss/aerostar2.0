import 'package:flutter/foundation.dart';

/// Connection state between the student and another person.
enum LinkState { none, requested, connected }

class Person {
  final String id;
  final String name;
  final String headline;
  final int mutual;
  final bool recruiter;
  LinkState link;
  Person({required this.id, required this.name, required this.headline, required this.mutual, this.recruiter = false, this.link = LinkState.none});

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

class Company {
  final String id;
  final String name;
  final String line;
  bool following;
  Company({required this.id, required this.name, required this.line, this.following = false});
}

class ChatMessage {
  final String text;
  final bool mine;
  final String time;
  const ChatMessage(this.text, this.mine, this.time);
}

class Conversation {
  final String id;
  final String personId;
  final String? about;
  final bool request; // message request that needs Accept
  bool unread;
  final List<ChatMessage> messages;
  Conversation({required this.id, required this.personId, this.about, this.request = false, this.unread = false, required List<ChatMessage> messages}) : messages = List.of(messages);

  ChatMessage get last => messages.last;
}

/// Mock people, companies and chats for the prototype. Shared by Home, Network and Messages so a
/// connection made in one place shows everywhere.
class NetworkStore extends ChangeNotifier {
  final List<Person> people = [
    Person(id: 'ar', name: 'Ananya Rao', headline: 'Talent Acquisition at Zerodha', mutual: 12, recruiter: true, link: LinkState.connected),
    Person(id: 'rm', name: 'Rohan Mehta', headline: 'Product Design Intern at CRED · NID Ahmedabad', mutual: 8),
    Person(id: 'pn', name: 'Priya Nair', headline: 'Marketing Manager at upGrad', mutual: 5, recruiter: true),
    Person(id: 'ki', name: 'Karthik Iyer', headline: 'B.Com, final year · Pune University', mutual: 21, link: LinkState.requested),
    Person(id: 'sq', name: 'Sana Qureshi', headline: 'HR Business Partner at Swiggy', mutual: 3, recruiter: true),
    Person(id: 'dk', name: 'Dev Kapoor', headline: 'Growth at Razorpay · IIM Indore', mutual: 9),
  ];

  /// People who sent the student a request (Accept / Ignore).
  final List<String> invitations = ['sq', 'dk'];

  final List<Company> companies = [
    Company(id: 'z', name: 'Zerodha', line: 'FinTech · Bengaluru · 12 open roles'),
    Company(id: 'c', name: 'CRED', line: 'FinTech · Bengaluru · 7 open roles'),
    Company(id: 'u', name: 'upGrad', line: 'EdTech · Mumbai · 9 open roles'),
  ];

  late final List<Conversation> conversations = [
    Conversation(id: 'c1', personId: 'ar', about: 'Digital Marketing Intern', unread: true, messages: const [
      ChatMessage('Hi Aarav, thanks for applying. Your portfolio looked good.', false, '10:02'),
      ChatMessage('Thank you! Happy to share more about the campaigns.', true, '10:08'),
      ChatMessage('Are you free for a short call on Thursday at 4 pm?', false, '10:15'),
      ChatMessage('Yes, Thursday works for me.', true, '10:16'),
    ]),
    Conversation(id: 'c2', personId: 'pn', request: true, unread: true, messages: const [
      ChatMessage('Hi Aarav, I saw your resume. We have a content marketing role that could suit you.', false, '9:41'),
    ]),
    Conversation(id: 'c3', personId: 'rm', messages: const [
      ChatMessage('Thanks for the referral!', false, 'Mon'),
    ]),
  ];

  Person person(String id) => people.firstWhere((p) => p.id == id);
  Conversation conversation(String id) => conversations.firstWhere((c) => c.id == id);
  Conversation? conversationWith(String personId) {
    for (final c in conversations) {
      if (c.personId == personId) return c;
    }
    return null;
  }

  List<Person> get invited => invitations.map(person).toList();
  List<Person> get suggestions => people.where((p) => p.link != LinkState.connected && !invitations.contains(p.id)).toList();
  int get connectionCount => 148 + people.where((p) => p.link == LinkState.connected).length - 1;
  bool get hasUnreadMessages => conversations.any((c) => c.unread);

  void connect(String id) {
    person(id).link = LinkState.requested;
    notifyListeners();
  }

  void accept(String id) {
    person(id).link = LinkState.connected;
    invitations.remove(id);
    notifyListeners();
  }

  void ignore(String id) {
    invitations.remove(id);
    notifyListeners();
  }

  void toggleFollow(String id) {
    final c = companies.firstWhere((c) => c.id == id);
    c.following = !c.following;
    notifyListeners();
  }

  void markRead(String id) {
    final c = conversation(id);
    if (c.unread) {
      c.unread = false;
      notifyListeners();
    }
  }

  void acceptRequest(String conversationId) {
    final c = conversation(conversationId);
    person(c.personId).link = LinkState.connected;
    conversations[conversations.indexOf(c)] = Conversation(id: c.id, personId: c.personId, about: c.about, request: false, unread: false, messages: c.messages);
    notifyListeners();
  }

  void send(String conversationId, String text) {
    final c = conversation(conversationId);
    c.messages.add(ChatMessage(text, true, 'Now'));
    notifyListeners();
  }

  /// Starts (or opens) a chat with a person; returns the conversation id.
  String openChat(String personId) {
    final existing = conversationWith(personId);
    if (existing != null) return existing.id;
    final c = Conversation(id: 'c_$personId', personId: personId, messages: []);
    conversations.insert(0, c);
    notifyListeners();
    return c.id;
  }
}
