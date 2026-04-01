/// ============================================================
/// Data Models — ThirdSpace
/// ============================================================
/// These models mirror the PRD requirements:
///   - Venue (with Vibe Tags, Live Occupancy)
///   - Beacon (user-generated meetups with capacity & expiry)
///   - StatusPulse (140-char proof-of-presence updates)
///   - UserProfile (with ghost score & vibe identity)
/// ============================================================
library;

import 'package:latlong2/latlong.dart';

/// Vibe categories from PRD Section 3.1
enum VibeTag {
  socialBuzz,
  deepWork,
  creativeFlow,
  quietContemplation,
}

extension VibeTagExtension on VibeTag {
  String get label {
    switch (this) {
      case VibeTag.socialBuzz:
        return '#SocialBuzz';
      case VibeTag.deepWork:
        return '#DeepWork';
      case VibeTag.creativeFlow:
        return '#CreativeFlow';
      case VibeTag.quietContemplation:
        return '#QuietContemplation';
    }
  }

  String get shortLabel {
    switch (this) {
      case VibeTag.socialBuzz:
        return 'Social';
      case VibeTag.deepWork:
        return 'Focus';
      case VibeTag.creativeFlow:
        return 'Creative';
      case VibeTag.quietContemplation:
        return 'Quiet';
    }
  }

  String get icon {
    switch (this) {
      case VibeTag.socialBuzz:
        return '🎉';
      case VibeTag.deepWork:
        return '🎧';
      case VibeTag.creativeFlow:
        return '🎨';
      case VibeTag.quietContemplation:
        return '🧘';
    }
  }
}

/// Venue — a physical "ThirdSpace" location
class Venue {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final List<VibeTag> vibes;
  final double crowdDensity; // 0.0 → 1.0
  final int checkinCount;
  final int activeBeaconCount;
  final String description;
  final double distanceKm;
  final List<StatusPulse> recentPulses;

  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.vibes,
    required this.crowdDensity,
    required this.checkinCount,
    required this.activeBeaconCount,
    required this.description,
    required this.distanceKm,
    this.recentPulses = const [],
  });

  /// Energy level label for the venue
  String get energyLevel {
    if (crowdDensity >= 0.7) return 'High';
    if (crowdDensity >= 0.4) return 'Medium';
    return 'Low';
  }

  Venue copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? location,
    List<VibeTag>? vibes,
    double? crowdDensity,
    int? checkinCount,
    int? activeBeaconCount,
    String? description,
    double? distanceKm,
    List<StatusPulse>? recentPulses,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      vibes: vibes ?? this.vibes,
      crowdDensity: crowdDensity ?? this.crowdDensity,
      checkinCount: checkinCount ?? this.checkinCount,
      activeBeaconCount: activeBeaconCount ?? this.activeBeaconCount,
      description: description ?? this.description,
      distanceKm: distanceKm ?? this.distanceKm,
      recentPulses: recentPulses ?? this.recentPulses,
    );
  }
}

/// Beacon — user-generated spontaneous meetup (PRD 3.2)
class Beacon {
  final String id;
  final String hostUserId; // Firebase UID of the host
  final String hostName;
  final String hostInitials;
  final String hostLevel;
  final String title;
  final String description;
  final LatLng location;
  final String locationName;
  final List<VibeTag> vibes;
  final int maxCapacity; // "Table Size" 2-6
  final int currentCount;
  final DateTime expiresAt; // Auto-expires after 3 hrs
  final DateTime createdAt;

  const Beacon({
    required this.id,
    this.hostUserId = '',
    required this.hostName,
    required this.hostInitials,
    required this.hostLevel,
    required this.title,
    required this.description,
    required this.location,
    required this.locationName,
    required this.vibes,
    required this.maxCapacity,
    required this.currentCount,
    required this.expiresAt,
    required this.createdAt,
  });

  /// Remaining time as human-readable string
  String get timeRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    final hrs = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    return '${hrs}h ${mins}m';
  }

  bool get isFull => currentCount >= maxCapacity;
  int get seatsLeft => maxCapacity - currentCount;
}

/// StatusPulse — 140-char "Vibe Check" proof of presence (PRD 3.3)
class StatusPulse {
  final String id;
  final String authorName;
  final String authorInitials;
  final String text;
  final DateTime createdAt;

  const StatusPulse({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    required this.text,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class UserProfile {
  final String name;
  final String initials;
  final String username; // unique @handle
  final String? photoUrl;
  final int checkinCount;
  final int beaconsLit;
  final int beaconsJoined;
  final int eventsSignedUpFor;  // total events user RSVPed / signed up for
  final int eventsAttended;     // total events user actually showed up to
  /// Per-vibe event counts: how many events of each vibe the user created/attended
  final Map<VibeTag, int> vibeEventCounts;

  const UserProfile({
    required this.name,
    required this.initials,
    this.username = '',
    this.photoUrl,
    this.checkinCount = 0,
    this.beaconsLit = 0,
    this.beaconsJoined = 0,
    this.eventsSignedUpFor = 0,
    this.eventsAttended = 0,
    this.vibeEventCounts = const <VibeTag, int>{},
  });

  /// Computed level based on total activity
  String get level {
    final total = checkinCount + beaconsLit + beaconsJoined;
    if (total >= 100) return 'Community Architect';
    if (total >= 50) return 'Level 10 Guide';
    if (total >= 25) return 'Level 7 Explorer';
    if (total >= 10) return 'Level 5 Explorer';
    if (total >= 5) return 'Level 3 Newcomer';
    if (total >= 1) return 'Level 1 Newcomer';
    return 'New Member';
  }

  /// Reliability score: eventsAttended / eventsSignedUpFor
  /// Starts at 0%. Returns 0.0 if no sign-ups yet.
  double get ghostScore {
    if (eventsSignedUpFor == 0) return 0.0;
    return (eventsAttended / eventsSignedUpFor).clamp(0.0, 1.0);
  }

  /// Vibe identity breakdown: vibeEvents / totalEvents for each vibe
  /// Returns 0.0 for all if no events attended.
  Map<VibeTag, double> get vibeIdentity {
    final totalEvents = checkinCount + beaconsLit + beaconsJoined;
    if (totalEvents == 0) {
      return {
        for (final vibe in VibeTag.values) vibe: 0.0,
      };
    }
    return {
      for (final vibe in VibeTag.values)
        vibe: (vibeEventCounts[vibe] ?? 0) / totalEvents,
    };
  }

  /// Build from Firestore document data
  factory UserProfile.fromFirestore(Map<String, dynamic> data, {String? displayName, String? photoUrlOverride}) {
    final name = (data['name'] as String?) ?? displayName ?? 'ThirdSpace User';
    final photoUrl = photoUrlOverride ?? data['photoUrl'] as String?;
    final vibeCounts = <VibeTag, int>{};
    final rawVibeData = data['vibeEventCounts'];
    final vibeData = rawVibeData is Map ? Map<String, dynamic>.from(rawVibeData) : <String, dynamic>{};
    for (final vibe in VibeTag.values) {
      final val = vibeData[vibe.name];
      vibeCounts[vibe] = (val is num) ? val.toInt() : 0;
    }
    return UserProfile(
      name: name,
      initials: computeInitials(name),
      username: (data['username'] as String?) ?? '',
      photoUrl: photoUrl,
      checkinCount: (data['checkinCount'] is num) ? (data['checkinCount'] as num).toInt() : 0,
      beaconsLit: (data['beaconsLit'] is num) ? (data['beaconsLit'] as num).toInt() : 0,
      beaconsJoined: (data['beaconsJoined'] is num) ? (data['beaconsJoined'] as num).toInt() : 0,
      eventsSignedUpFor: (data['eventsSignedUpFor'] is num) ? (data['eventsSignedUpFor'] as num).toInt() : 0,
      eventsAttended: (data['eventsAttended'] is num) ? (data['eventsAttended'] as num).toInt() : 0,
      vibeEventCounts: vibeCounts,
    );
  }

  static String computeInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  UserProfile copyWith({
    String? name,
    String? initials,
    String? username,
    String? photoUrl,
    int? checkinCount,
    int? beaconsLit,
    int? beaconsJoined,
    int? eventsSignedUpFor,
    int? eventsAttended,
    Map<VibeTag, int>? vibeEventCounts,
  }) {
    return UserProfile(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      checkinCount: checkinCount ?? this.checkinCount,
      beaconsLit: beaconsLit ?? this.beaconsLit,
      beaconsJoined: beaconsJoined ?? this.beaconsJoined,
      eventsSignedUpFor: eventsSignedUpFor ?? this.eventsSignedUpFor,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      vibeEventCounts: vibeEventCounts ?? this.vibeEventCounts,
    );
  }
}

/// Activity types for the Activity feed
enum ActivityType {
  checkin,
  beaconLit,
  beaconJoined,
  pulseSent,
}

/// ActivityItem — represents one event in the user's activity timeline
class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final VibeTag? vibe;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.vibe,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// ============================================================
/// Messaging Models
/// ============================================================

/// Conversation — a DM thread between two users
class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String> participantInitials;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageBy;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantInitials,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageBy,
    this.unreadCount = 0,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  /// Get the other participant's name given the current user's ID
  String otherName(String myUserId) {
    final otherId = participants.firstWhere(
      (id) => id != myUserId,
      orElse: () => participants.first,
    );
    return participantNames[otherId] ?? 'Unknown';
  }

  String otherInitials(String myUserId) {
    final otherId = participants.firstWhere(
      (id) => id != myUserId,
      orElse: () => participants.first,
    );
    return participantInitials[otherId] ?? 'U';
  }

  String otherId(String myUserId) {
    return participants.firstWhere(
      (id) => id != myUserId,
      orElse: () => participants.first,
    );
  }
}

/// Message — a single chat message
class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool read;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    this.read = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// ============================================================
/// Notification Model
/// ============================================================

enum NotificationType {
  joinRequest,
  requestAccepted,
  requestDeclined,
  newMessage,
}

/// AppNotification — in-app notification for beacon requests, messages, etc.
class AppNotification {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final String? beaconId;
  final String? beaconTitle;
  final String? requesterId;
  final String? requesterName;
  final bool read;
  final bool actionTaken;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.beaconId,
    this.beaconTitle,
    this.requesterId,
    this.requesterName,
    this.read = false,
    this.actionTaken = false,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
