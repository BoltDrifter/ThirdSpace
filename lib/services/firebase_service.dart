library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models.dart';
import 'package:latlong2/latlong.dart';

/// Service class for interacting with Firebase Firestore.
/// Handles venues, beacons, check-ins, and pulse events.
class FirebaseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Venues ──
  Stream<List<Venue>> streamVenues() {
    return _firestore.collection('venues').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Venue(
          id: doc.id,
          name: data['name'] ?? '',
          address: data['address'] ?? '',
          location: LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          ),
          vibes: (data['vibes'] as List<dynamic>?)
                  ?.map((v) => VibeTag.values.firstWhere((e) => e.name == v))
                  .toList() ??
              [],
          crowdDensity: (data['crowdDensity'] as num?)?.toDouble() ?? 0.0,
          checkinCount: data['checkinCount'] ?? 0,
          activeBeaconCount: data['activeBeaconCount'] ?? 0,
          description: data['description'] ?? '',
          distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    });
  }

  // ── Beacons ──
  Stream<List<Beacon>> streamBeacons() {
    // Simple query without compound index requirement
    return _firestore
        .collection('beacons')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            try {
              final expiresAt = (data['expiresAt'] as Timestamp).toDate();
              if (expiresAt.isBefore(now)) return null; // Filter expired
              return Beacon(
                id: doc.id,
                hostUserId: data['hostUserId'] ?? '',
                hostName: data['hostName'] ?? '',
                hostInitials: data['hostInitials'] ?? '',
                hostLevel: data['hostLevel'] ?? '',
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                location: LatLng(
                  (data['lat'] as num).toDouble(),
                  (data['lng'] as num).toDouble(),
                ),
                locationName: data['locationName'] ?? '',
                vibes: (data['vibes'] as List<dynamic>?)
                        ?.map((v) =>
                            VibeTag.values.firstWhere((e) => e.name == v))
                        .toList() ??
                    [],
                maxCapacity: data['maxCapacity'] ?? 4,
                currentCount: data['currentCount'] ?? 1,
                expiresAt: expiresAt,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            } catch (e) {
              print('Error parsing beacon: $e');
              return null;
            }
          })
          .whereType<Beacon>()
          .toList();
    });
  }

  // ── Create Beacon ──
  Future<void> createBeacon(Beacon beacon) async {
    // Use .add() for auto-generated ID to avoid permission issues with custom IDs
    await _firestore.collection('beacons').add({
      'hostUserId': beacon.hostUserId,
      'hostName': beacon.hostName,
      'hostInitials': beacon.hostInitials,
      'hostLevel': beacon.hostLevel,
      'title': beacon.title,
      'description': beacon.description,
      'lat': beacon.location.latitude,
      'lng': beacon.location.longitude,
      'locationName': beacon.locationName,
      'vibes': beacon.vibes.map((v) => v.name).toList(),
      'maxCapacity': beacon.maxCapacity,
      'currentCount': beacon.currentCount,
      'expiresAt': Timestamp.fromDate(beacon.expiresAt),
      'createdAt': Timestamp.fromDate(beacon.createdAt),
      'joinRequests': [],
    });
  }

  // ── Join Beacon Request ──
  Future<void> requestJoinBeacon({
    required String beaconId,
    required String userId,
    required String userName,
    String? message,
  }) async {
    final request = {
      'userId': userId,
      'userName': userName,
      'message': message ?? '',
      'status': 'pending',
      'requestedAt': Timestamp.now(), // Array union doesn't support FieldValue.serverTimestamp() directly inside complex objects, but Timestamp.now() is fine.
    };
    
    await _firestore.collection('beacons').doc(beaconId).update({
      'joinRequests': FieldValue.arrayUnion([request])
    });
  }

  // ── Check In to Venue ──
  Future<void> recordCheckIn({
    required String venueId,
    required String userId,
    required String userName,
  }) async {
    final batch = _firestore.batch();

    final checkInRef = _firestore
        .collection('venues')
        .doc(venueId)
        .collection('checkins')
        .doc();
    batch.set(checkInRef, {
      'userId': userId,
      'userName': userName,
      'checkedInAt': FieldValue.serverTimestamp(),
    });

    final venueRef = _firestore.collection('venues').doc(venueId);
    batch.update(venueRef, {
      'checkinCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ── Send Status Pulse ──
  Future<void> sendPulse({
    required String venueId,
    required String userId,
    required String userName,
    required String userInitials,
    required String text,
  }) async {
    await _firestore
        .collection('venues')
        .doc(venueId)
        .collection('pulses')
        .add({
      'userId': userId,
      'authorName': userName,
      'authorInitials': userInitials,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Save User Profile ──
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final docRef = _firestore.collection('users').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      // Existing user — just update login info
      await docRef.update({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      // New user — initialize all stats at 0
      await docRef.set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'checkinCount': 0,
        'beaconsLit': 0,
        'beaconsJoined': 0,
        'eventsSignedUpFor': 0,
        'eventsAttended': 0,
        'vibeEventCounts': {},
      });
    }
  }

  // ── Stream User Profile (real-time stats) ──
  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // ── Update User Stats ──
  Future<void> incrementUserStat({
    required String userId,
    required String field,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        field: FieldValue.increment(1),
      });
    } catch (e) {
      // If the document doesn't exist yet, create with initial stat
      await _firestore.collection('users').doc(userId).set({
        field: 1,
      }, SetOptions(merge: true));
    }
  }

  // ── Increment Vibe Event Count ──
  /// Increments the count for specific vibe tags when user creates/joins/attends an event
  Future<void> incrementVibeEventCounts({
    required String userId,
    required List<VibeTag> vibes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      for (final vibe in vibes) {
        updates['vibeEventCounts.${vibe.name}'] = FieldValue.increment(1);
      }
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      debugPrint('Error incrementing vibe event counts: $e');
    }
  }

  // ── Stream User Events (Activity Feed) ──
  Stream<List<Map<String, dynamic>>> streamUserActivity(String userId) {
    return _firestore
        .collection('activity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // ── Log Activity Event ──
  Future<void> logActivity({
    required String userId,
    required String type,
    required String title,
    required String subtitle,
    String? vibeTag,
  }) async {
    try {
      await _firestore.collection('activity').add({
        'userId': userId,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'vibeTag': vibeTag,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail activity logging — don't block the primary action
    }
  }

  // ── Stream Join Requests for a Beacon ──
  Stream<List<Map<String, dynamic>>> streamJoinRequests(String beaconId) {
    return _firestore
        .collection('beacons')
        .doc(beaconId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data()!;
      final list = data['joinRequests'] as List<dynamic>? ?? [];
      final requests = list.map((e) => Map<String, dynamic>.from(e)).toList();
      
      // Sort locally
      requests.sort((a, b) {
        final aTime = a['requestedAt'] as Timestamp?;
        final bTime = b['requestedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return requests;
    });
  }

  // ── Accept Join Request ──
  Future<void> acceptJoinRequest({
    required String beaconId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('beacons').doc(beaconId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final list = List<Map<String, dynamic>>.from(data['joinRequests'] ?? []);
      
      final index = list.indexWhere((r) => r['userId'] == userId);
      if (index != -1) {
        list[index]['status'] = 'accepted';
        transaction.update(docRef, {
          'joinRequests': list,
          'currentCount': FieldValue.increment(1),
        });
      }
    });
  }

  // ── Decline Join Request ──
  Future<void> declineJoinRequest({
    required String beaconId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('beacons').doc(beaconId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final list = List<Map<String, dynamic>>.from(data['joinRequests'] ?? []);
      
      final index = list.indexWhere((r) => r['userId'] == userId);
      if (index != -1) {
        list[index]['status'] = 'declined';
        transaction.update(docRef, {
          'joinRequests': list,
        });
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGING
  // ══════════════════════════════════════════════════════════════

  /// Get or create a conversation between two users
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userName1,
    required String userInitials1,
    required String userId2,
    required String userName2,
    required String userInitials2,
  }) async {
    // Check if conversation already exists between these two users
    final existing = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId1)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(userId2)) {
        return doc.id; // Conversation already exists
      }
    }

    // Create new conversation
    final docRef = await _firestore.collection('conversations').add({
      'participants': [userId1, userId2],
      'participantNames': {userId1: userName1, userId2: userName2},
      'participantInitials': {userId1: userInitials1, userId2: userInitials2},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageBy': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Stream conversations for a user
  Stream<List<Conversation>> streamConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs.map((doc) {
        final data = doc.data();
        try {
          final nameMap = Map<String, String>.from(
              (data['participantNames'] as Map?)?.cast<String, String>() ?? {});
          final initialsMap = Map<String, String>.from(
              (data['participantInitials'] as Map?)?.cast<String, String>() ?? {});
          return Conversation(
            id: doc.id,
            participants: List<String>.from(data['participants'] ?? []),
            participantNames: nameMap,
            participantInitials: initialsMap,
            lastMessage: data['lastMessage'] ?? '',
            lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastMessageBy: data['lastMessageBy'] ?? '',
          );
        } catch (e) {
          debugPrint('Error parsing conversation: $e');
          return null;
        }
      }).whereType<Conversation>().toList();

      // Sort locally by last message time
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return conversations;
    });
  }

  /// Stream messages for a conversation
  Stream<List<Message>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          text: data['text'] ?? '',
          sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          read: data['read'] ?? false,
        );
      }).toList();
    });
  }

  /// Send a message in a conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Update conversation metadata
    final convRef = _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageBy': senderId,
    });

    await batch.commit();
  }

  /// Look up a user's name and initials by their userId
  Future<Map<String, String>> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final name = data['name'] as String? ?? 'User';
        final parts = name.trim().split(' ');
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name.isNotEmpty
                ? name[0].toUpperCase()
                : 'U';
        return {'name': name, 'initials': initials};
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
    return {'name': 'User', 'initials': 'U'};
  }

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════

  /// Create a notification
  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? beaconId,
    String? beaconTitle,
    String? requesterId,
    String? requesterName,
  }) async {
    await _firestore.collection('notifications').add({
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'body': body,
      'beaconId': beaconId,
      'beaconTitle': beaconTitle,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'read': false,
      'actionTaken': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream notifications for a user
  Stream<List<AppNotification>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        try {
          return AppNotification(
            id: doc.id,
            recipientId: data['recipientId'] ?? '',
            type: _parseNotificationType(data['type']),
            title: data['title'] ?? '',
            body: data['body'] ?? '',
            beaconId: data['beaconId'],
            beaconTitle: data['beaconTitle'],
            requesterId: data['requesterId'],
            requesterName: data['requesterName'],
            read: data['read'] ?? false,
            actionTaken: data['actionTaken'] ?? false,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        } catch (e) {
          debugPrint('Error parsing notification: $e');
          return null;
        }
      }).whereType<AppNotification>().toList();

      // Sort locally by createdAt descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'joinRequest':
        return NotificationType.joinRequest;
      case 'requestAccepted':
        return NotificationType.requestAccepted;
      case 'requestDeclined':
        return NotificationType.requestDeclined;
      case 'newMessage':
        return NotificationType.newMessage;
      default:
        return NotificationType.joinRequest;
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  /// Mark notification action taken
  Future<void> markNotificationActionTaken(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'actionTaken': true,
      'read': true,
    });
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

