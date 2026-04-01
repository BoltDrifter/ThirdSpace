/// ============================================================
/// App State — ThirdSpace (Provider)
/// ============================================================
/// Central state management with:
///   - Firebase Auth integration
///   - Real-time GPS location tracking
///   - Firebase Firestore streams for venues/beacons
///   - Messaging & Notification state
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'models.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final AuthService _authService = AuthService();

  // ── Navigation ──
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;

  void setTab(int index) {
    if (index < 0 || index > 3) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  // ── Authentication ──
  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  AuthService get authService => _authService;
  StreamSubscription? _authSub;

  // ── Location ──
  LatLng? _userLocation;
  LatLng? get userLocation => _userLocation;
  bool _locationLoading = true;
  bool get locationLoading => _locationLoading;
  StreamSubscription<Position>? _positionSub;

  // ── Venues ──
  List<Venue> _venues = [];
  List<Venue> get venues => _venues;

  Venue? _selectedVenue;
  Venue? get selectedVenue => _selectedVenue;

  void selectVenue(Venue venue) {
    _selectedVenue = venue;
    notifyListeners();
  }

  void clearVenueSelection() {
    _selectedVenue = null;
    notifyListeners();
  }

  // ── Beacons ──
  List<Beacon> _beacons = [];
  List<Beacon> get beacons => _beacons;

  /// Beacons created by the current user
  List<Beacon> get myBeacons {
    if (_firebaseUser == null) return [];
    return _beacons.where((b) => b.hostUserId == _firebaseUser!.uid).toList();
  }

  /// Expose firebase service for screens that need direct stream access
  FirebaseDataService get firebaseService => _firebaseService;

  // ── Vibe Filter ──
  VibeTag? _activeVibeFilter;
  VibeTag? get activeVibeFilter => _activeVibeFilter;

  void setVibeFilter(VibeTag? vibe) {
    _activeVibeFilter = vibe;
    notifyListeners();
  }

  List<Venue> get filteredVenues {
    if (_activeVibeFilter == null) return _venues;
    return _venues.where((v) => v.vibes.contains(_activeVibeFilter)).toList();
  }

  List<Beacon> get filteredBeacons {
    var filtered = _beacons;
    
    // Filter by distance (10km max)
    if (_userLocation != null) {
      const distanceCalc = Distance();
      filtered = filtered.where((b) {
        final dist = distanceCalc.as(LengthUnit.Kilometer, _userLocation!, b.location);
        return dist <= 10;
      }).toList();
    }

    if (_activeVibeFilter != null) {
      filtered = filtered.where((b) => b.vibes.contains(_activeVibeFilter)).toList();
    }
    
    return filtered;
  }

  // ── User Profile ──
  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  // ── Activity Feed ──
  List<ActivityItem> get activityFeed {
    final items = <ActivityItem>[];

    // Recent pulses from all venues
    for (final venue in _venues) {
      for (final pulse in venue.recentPulses) {
        items.add(ActivityItem(
          id: 'pulse_${pulse.id}',
          type: ActivityType.pulseSent,
          title: '${pulse.authorName} sent a pulse',
          subtitle: '${pulse.text}\n📍 ${venue.name}',
          timestamp: pulse.createdAt,
          vibe: venue.vibes.isNotEmpty ? venue.vibes.first : null,
        ));
      }
    }

    // Recent beacons as activity
    for (final beacon in _beacons) {
      items.add(ActivityItem(
        id: 'beacon_${beacon.id}',
        type: ActivityType.beaconLit,
        title: '${beacon.hostName} lit a beacon',
        subtitle: '${beacon.title}\n📍 ${beacon.locationName}',
        timestamp: beacon.createdAt,
        vibe: beacon.vibes.isNotEmpty ? beacon.vibes.first : null,
      ));
    }

    // Sort by time (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// All recent pulses aggregated from all venues
  List<StatusPulse> get allRecentPulses {
    final pulses = <StatusPulse>[];
    for (final venue in _venues) {
      pulses.addAll(venue.recentPulses);
    }
    pulses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pulses;
  }

  /// Top trending venues by crowd density
  List<Venue> get trendingVenues {
    final sorted = List<Venue>.from(_venues);
    sorted.sort((a, b) => b.crowdDensity.compareTo(a.crowdDensity));
    return sorted.take(5).toList();
  }

  // ── Notifications ──
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;
  StreamSubscription? _notificationsSub;

  // ── Conversations ──
  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;
  int get unreadConversationCount =>
      _conversations.where((c) => c.lastMessageBy.isNotEmpty && c.lastMessageBy != _firebaseUser?.uid && c.lastMessage.isNotEmpty).length;
  StreamSubscription? _conversationsSub;

  // ── Toast Messages ──
  String? _toastMessage;
  String? get toastMessage => _toastMessage;

  void showToast(String message) {
    _toastMessage = message;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _toastMessage = null;
      notifyListeners();
    });
  }

  // ── Initialization ──
  AppState() {
    _initAuth();
  }

  StreamSubscription? _venuesSub;
  StreamSubscription? _beaconsSub;
  StreamSubscription? _userProfileSub;

  void _initAuth() {
    _authSub = _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      if (user != null) {
        _loadData();
        _initLocation();
        _streamUserProfile(user);
        _streamNotifications(user.uid);
        _streamConversations(user.uid);
        // Save user profile to Firestore (initializes stats for new users)
        _firebaseService.saveUserProfile(
          userId: user.uid,
          name: user.displayName ?? 'ThirdSpace User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
      } else {
        // User logged out — clean up
        _venuesSub?.cancel();
        _beaconsSub?.cancel();
        _userProfileSub?.cancel();
        _positionSub?.cancel();
        _notificationsSub?.cancel();
        _conversationsSub?.cancel();
        _venues = [];
        _beacons = [];
        _userLocation = null;
        _userProfile = null;
        _notifications = [];
        _conversations = [];
        _currentTabIndex = 0;
      }
      notifyListeners();
    });
  }

  /// Stream the user's profile document from Firestore for real-time stats
  void _streamUserProfile(User user) {
    _userProfileSub?.cancel();
    _userProfileSub = _firebaseService.streamUserProfile(user.uid).listen(
      (data) {
        if (data != null) {
          _userProfile = UserProfile.fromFirestore(
            data,
            displayName: _firebaseUser?.displayName,
          );
        } else {
          // No Firestore doc yet — create a default empty profile
          _userProfile = UserProfile(
            name: _firebaseUser?.displayName ?? 'ThirdSpace User',
            initials: _getInitials(_firebaseUser?.displayName ?? 'TS'),
          );
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming user profile: $e');
        // Fallback to empty profile
        _userProfile = UserProfile(
          name: _firebaseUser?.displayName ?? 'ThirdSpace User',
          initials: _getInitials(_firebaseUser?.displayName ?? 'TS'),
        );
        notifyListeners();
      },
    );
  }

  /// Stream notifications for the current user
  void _streamNotifications(String userId) {
    _notificationsSub?.cancel();
    _notificationsSub = _firebaseService.streamNotifications(userId).listen(
      (data) {
        _notifications = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming notifications: $e');
      },
    );
  }

  /// Stream conversations for the current user
  void _streamConversations(String userId) {
    _conversationsSub?.cancel();
    _conversationsSub = _firebaseService.streamConversations(userId).listen(
      (data) {
        _conversations = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming conversations: $e');
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String? _lastStreamError;
  String? get lastStreamError => _lastStreamError;

  void _loadData() {
    _venuesSub?.cancel();
    _beaconsSub?.cancel();
    _lastStreamError = null;

    // Subscribe to real-time venues
    _venuesSub = _firebaseService.streamVenues().listen(
      (data) {
        _venues = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming venues: $e');
        _lastStreamError = e.toString();
        notifyListeners();
        // Retry after delay to recover from closed streams
        Future.delayed(const Duration(seconds: 5), _loadData);
      },
      cancelOnError: false,
    );

    // Subscribe to real-time beacons
    _beaconsSub = _firebaseService.streamBeacons().listen(
      (data) {
        _beacons = data;
        _lastStreamError = null;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Error streaming beacons: $e');
        _lastStreamError = e.toString();
        notifyListeners();
        // Retry after delay to recover
        Future.delayed(const Duration(seconds: 5), _loadData);
      },
      cancelOnError: false,
    );
  }

  Future<void> refreshData() async {
     _loadData();
     notifyListeners();
     // Wait a short moment to allow the UI to show the pull-to-refresh circle
     await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _initLocation() async {
    _locationLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationLoading = false;
        notifyListeners();
        return;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userLocation = LatLng(position.latitude, position.longitude);
      _locationLoading = false;
      notifyListeners();

      // Start listening for position updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((position) {
        _userLocation = LatLng(position.latitude, position.longitude);
        notifyListeners();
      });
    } catch (e) {
      _locationLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _venuesSub?.cancel();
    _beaconsSub?.cancel();
    _userProfileSub?.cancel();
    _positionSub?.cancel();
    _notificationsSub?.cancel();
    _conversationsSub?.cancel();
    super.dispose();
  }

  // ── Beacon Actions ──
  Future<void> requestJoinBeacon(String beaconId) async {
    if (_firebaseUser == null) return;
    try {
      // Find the beacon to get its vibes and host
      final beacon = _beacons.where((b) => b.id == beaconId).firstOrNull;
      
      await _firebaseService.requestJoinBeacon(
        beaconId: beaconId,
        userId: _firebaseUser!.uid,
        userName: _userProfile?.name ?? 'Unknown',
      );
      await _firebaseService.logActivity(
        userId: _firebaseUser!.uid,
        type: 'beaconJoined',
        title: 'Requested to join a beacon',
        subtitle: 'Beacon ID: $beaconId',
      );
      // Increment beaconsJoined stat
      await _firebaseService.incrementUserStat(
        userId: _firebaseUser!.uid,
        field: 'beaconsJoined',
      );
      // Track events signed up for (joining = signing up)
      await _firebaseService.incrementUserStat(
        userId: _firebaseUser!.uid,
        field: 'eventsSignedUpFor',
      );
      // Track vibe event counts for the beacon's vibes
      if (beacon != null && beacon.vibes.isNotEmpty) {
        await _firebaseService.incrementVibeEventCounts(
          userId: _firebaseUser!.uid,
          vibes: beacon.vibes,
        );
      }

      // ── Create notification for the beacon host ──
      if (beacon != null && beacon.hostUserId.isNotEmpty) {
        await _firebaseService.createNotification(
          recipientId: beacon.hostUserId,
          type: 'joinRequest',
          title: 'New Join Request',
          body: '${_userProfile?.name ?? "Someone"} wants to join "${beacon.title}"',
          beaconId: beaconId,
          beaconTitle: beacon.title,
          requesterId: _firebaseUser!.uid,
          requesterName: _userProfile?.name ?? 'Unknown',
        );
      }

      showToast('Join request sent! Waiting for host approval 🤝');
    } catch (e) {
      showToast('Failed to send join request: $e');
    }
  }

  Future<void> dropBeacon({
    required String title,
    required String description,
    required List<VibeTag> vibes,
    required int tableSize,
    required int durationHours,
  }) async {
    // Use real device location if available, fallback to default
    final location = _userLocation ?? const LatLng(35.6590, 139.7000);

    final newBeacon = Beacon(
      id: 'b_new_${DateTime.now().millisecondsSinceEpoch}',
      hostUserId: _firebaseUser?.uid ?? '',
      hostName: _userProfile?.name ?? 'You',
      hostInitials: _userProfile?.initials ?? 'ME',
      hostLevel: _userProfile?.level ?? 'Explorer',
      title: title,
      description: description,
      location: location,
      locationName: 'Your Current Location',
      vibes: vibes,
      maxCapacity: tableSize,
      currentCount: 1,
      expiresAt: DateTime.now().add(Duration(hours: durationHours)),
      createdAt: DateTime.now(),
    );

    try {
      showToast('🔥 Lighting beacon... Broadcasting to Firebase network!');
      await _firebaseService.createBeacon(newBeacon);
      // Log activity
      if (_firebaseUser != null) {
        await _firebaseService.logActivity(
          userId: _firebaseUser!.uid,
          type: 'beaconLit',
          title: '${_userProfile?.name ?? "You"} lit a beacon',
          subtitle: '$title\n📍 Your Current Location',
          vibeTag: vibes.isNotEmpty ? vibes.first.name : null,
        );
        await _firebaseService.incrementUserStat(
          userId: _firebaseUser!.uid,
          field: 'beaconsLit',
        );
        // Track events signed up for & attended (creator = shows up)
        await _firebaseService.incrementUserStat(
          userId: _firebaseUser!.uid,
          field: 'eventsSignedUpFor',
        );
        await _firebaseService.incrementUserStat(
          userId: _firebaseUser!.uid,
          field: 'eventsAttended',
        );
        // Track vibe event counts
        if (vibes.isNotEmpty) {
          await _firebaseService.incrementVibeEventCounts(
            userId: _firebaseUser!.uid,
            vibes: vibes,
          );
        }
      }
      showToast('Broadcast successful!');
    } catch (e) {
      showToast('Error lighting beacon: $e');
    }
  }

  // ── Check-In (Real Location Verification) ──
  Future<void> checkInToVenue(String venueId) async {
    final venueIndex = _venues.indexWhere((v) => v.id == venueId);
    if (venueIndex == -1) return;

    final targetVenue = _venues[venueIndex];

    try {
      showToast('Verifying your location...');

      // Use cached location if available
      LatLng userPos;
      if (_userLocation != null) {
        userPos = _userLocation!;
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          showToast('Please enable location services.');
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            showToast('Location permissions denied.');
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          showToast('Location permissions are permanently denied.');
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        userPos = LatLng(position.latitude, position.longitude);
      }

      const Distance distanceCalculator = Distance();
      final distanceInMeters = distanceCalculator.as(
        LengthUnit.Meter,
        userPos,
        targetVenue.location,
      );

      if (distanceInMeters <= 50) {
        // Record check-in in Firestore
        if (_firebaseUser != null) {
          await _firebaseService.recordCheckIn(
            venueId: venueId,
            userId: _firebaseUser!.uid,
            userName: _userProfile?.name ?? 'Unknown',
          );
          await _firebaseService.logActivity(
            userId: _firebaseUser!.uid,
            type: 'checkin',
            title: '${_userProfile?.name ?? "You"} checked in',
            subtitle: '📍 ${targetVenue.name}',
            vibeTag: targetVenue.vibes.isNotEmpty ? targetVenue.vibes.first.name : null,
          );
          await _firebaseService.incrementUserStat(
            userId: _firebaseUser!.uid,
            field: 'checkinCount',
          );
          // Track events attended (check-in = attended)
          await _firebaseService.incrementUserStat(
            userId: _firebaseUser!.uid,
            field: 'eventsAttended',
          );
          // Track vibe event counts for the venue's vibes
          if (targetVenue.vibes.isNotEmpty) {
            await _firebaseService.incrementVibeEventCounts(
              userId: _firebaseUser!.uid,
              vibes: targetVenue.vibes,
            );
          }
        }
        _venues[venueIndex] = targetVenue.copyWith(
          checkinCount: targetVenue.checkinCount + 1,
        );
        showToast('✅ Checked in successfully!');
        if (_selectedVenue?.id == venueId) {
          _selectedVenue = _venues[venueIndex];
        }
        notifyListeners();
      } else {
        showToast(
            'Too far! Get within 50m to check in. (You are ${distanceInMeters.toInt()}m away)');
      }
    } catch (e) {
      showToast('Failed to get location: $e');
    }
  }

  // ── Send Pulse ──
  Future<void> sendPulse(String venueId, String text) async {
    if (text.isEmpty || text.length > 140) return;
    if (_firebaseUser == null) return;

    try {
      await _firebaseService.sendPulse(
        venueId: venueId,
        userId: _firebaseUser!.uid,
        userName: _userProfile?.name ?? 'Unknown',
        userInitials: _userProfile?.initials ?? 'U',
        text: text,
      );
      await _firebaseService.logActivity(
        userId: _firebaseUser!.uid,
        type: 'pulseSent',
        title: '${_userProfile?.name ?? "You"} sent a pulse',
        subtitle: text,
      );
      showToast('💫 Pulse sent!');
    } catch (e) {
      showToast('Failed to send pulse: $e');
    }
  }

  // ── Vibe Vote ──
  Future<void> voteVibe(String venueId, VibeTag vibe) async {
    if (_firebaseUser == null) return;
    try {
      await _firebaseService.logActivity(
        userId: _firebaseUser!.uid,
        type: 'vibeVote',
        title: '${_userProfile?.name ?? "You"} voted ${vibe.label}',
        subtitle: 'Venue: $venueId',
        vibeTag: vibe.name,
      );
      showToast('Voted ${vibe.label}!');
    } catch (e) {
      showToast('Voted ${vibe.label}!');
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Accept Join Request ──
  Future<void> acceptJoinRequest({
    required String beaconId,
    required String userId,
    String? notificationId,
  }) async {
    try {
      await _firebaseService.acceptJoinRequest(
        beaconId: beaconId,
        userId: userId,
      );
      // Increment the joiner's eventsAttended stat
      await _firebaseService.incrementUserStat(
        userId: userId,
        field: 'eventsAttended',
      );

      // Mark notification action taken if provided
      if (notificationId != null) {
        await _firebaseService.markNotificationActionTaken(notificationId);
      }

      // Create notification for the requester that their request was accepted
      final beacon = _beacons.where((b) => b.id == beaconId).firstOrNull;
      await _firebaseService.createNotification(
        recipientId: userId,
        type: 'requestAccepted',
        title: 'Request Accepted! 🎉',
        body: 'Your request to join "${beacon?.title ?? 'a beacon'}" was accepted!',
        beaconId: beaconId,
        beaconTitle: beacon?.title,
      );

      showToast('Request accepted! 🤝');
    } catch (e) {
      showToast('Failed to accept request: $e');
    }
  }

  // ── Decline Join Request ──
  Future<void> declineJoinRequest({
    required String beaconId,
    required String userId,
    String? notificationId,
  }) async {
    try {
      await _firebaseService.declineJoinRequest(
        beaconId: beaconId,
        userId: userId,
      );

      // Mark notification action taken if provided
      if (notificationId != null) {
        await _firebaseService.markNotificationActionTaken(notificationId);
      }

      // Create notification for the requester
      final beacon = _beacons.where((b) => b.id == beaconId).firstOrNull;
      await _firebaseService.createNotification(
        recipientId: userId,
        type: 'requestDeclined',
        title: 'Request Declined',
        body: 'Your request to join "${beacon?.title ?? 'a beacon'}" was declined.',
        beaconId: beaconId,
        beaconTitle: beacon?.title,
      );

      showToast('Request declined.');
    } catch (e) {
      showToast('Failed to decline request: $e');
    }
  }

  // ── Mark all notifications read ──
  Future<void> markAllNotificationsRead() async {
    if (_firebaseUser == null) return;
    try {
      await _firebaseService.markAllNotificationsRead(_firebaseUser!.uid);
    } catch (e) {
      debugPrint('Error marking notifications read: $e');
    }
  }

  // ── Start a conversation with a user ──
  Future<String?> startConversation(String otherUserId) async {
    if (_firebaseUser == null) return null;
    try {
      final otherInfo = await _firebaseService.getUserInfo(otherUserId);
      final conversationId = await _firebaseService.getOrCreateConversation(
        userId1: _firebaseUser!.uid,
        userName1: _userProfile?.name ?? 'Unknown',
        userInitials1: _userProfile?.initials ?? 'U',
        userId2: otherUserId,
        userName2: otherInfo['name'] ?? 'User',
        userInitials2: otherInfo['initials'] ?? 'U',
      );
      return conversationId;
    } catch (e) {
      showToast('Failed to start conversation: $e');
      return null;
    }
  }

  // ── Send a message ──
  Future<void> sendChatMessage({
    required String conversationId,
    required String text,
  }) async {
    if (_firebaseUser == null || text.isEmpty) return;
    try {
      await _firebaseService.sendMessage(
        conversationId: conversationId,
        senderId: _firebaseUser!.uid,
        senderName: _userProfile?.name ?? 'Unknown',
        text: text,
      );
    } catch (e) {
      showToast('Failed to send message: $e');
    }
  }

  // ── Update Profile ──
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (_firebaseUser == null) return;
    
    final newName = (name != null && name.isNotEmpty) ? name.trim() : _firebaseUser!.displayName ?? 'ThirdSpace User';
    final newPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl.trim() : null;

    // 1. Optimistically update local state so UI reflects instantly 
    // without waiting for Firebase or throwing exceptions
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        name: newName,
        photoUrl: newPhotoUrl,
      );
      notifyListeners();
    }

    // 2. Wrap the buggy firebase_auth platform code in its own try/catch
    // This allows it to fail silently on older pigeon bindings without 
    // crashing the rest of the profile update process.
    try {
      if (name != null) await _firebaseUser!.updateDisplayName(newName);
      if (photoUrl != null) await _firebaseUser!.updatePhotoURL(newPhotoUrl);
      await _firebaseUser!.reload();
      _firebaseUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Silently caught firebase_auth update exception: $e');
    }

    // 3. Actually save the authoritative update to Firestore
    try {
      await _firebaseService.saveUserProfile(
        userId: _firebaseUser!.uid,
        name: newName,
        email: _firebaseUser!.email ?? '',
        photoUrl: newPhotoUrl,
      );

      // Force update local profile for instant UI responsiveness
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          name: newName,
          initials: _getInitials(newName),
          photoUrl: newPhotoUrl,
        );
      }
      
      showToast('Profile updated successfully! ✨');
      notifyListeners();
    } catch (e) {
      showToast('Failed to update profile: $e');
    }
  }
}

