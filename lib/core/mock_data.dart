/// ============================================================
/// Mock Data Service — ThirdSpace
/// ============================================================
/// Provides realistic sample data for the MVP.
/// In production, replace with FirebaseDataService or
/// SupabaseDataService implementing the same interface.
/// ============================================================
library;

import 'package:latlong2/latlong.dart';
import 'models.dart';

class MockDataService {
  /// Active venues near user (from Stitch MCP screen data)
  static List<Venue> getVenues() {
    return [
      Venue(
        id: 'shibuya',
        name: 'Shibuya Crossing Peak',
        address: '1-2-1 Dogenzaka, Shibuya City',
        location: const LatLng(35.6595, 139.7004),
        vibes: [VibeTag.socialBuzz, VibeTag.creativeFlow],
        crowdDensity: 0.92,
        checkinCount: 47,
        activeBeaconCount: 3,
        description:
            'The center of energy. Bustling with creative nomads and social butterflies.',
        distanceKm: 0.3,
        recentPulses: [
          StatusPulse(
            id: 'p1',
            authorName: 'Alex K.',
            authorInitials: 'AK',
            text:
                'Incredible vibes today! Every seat taken but the energy is electric ⚡',
            createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
          StatusPulse(
            id: 'p2',
            authorName: 'Lena M.',
            authorInitials: 'LM',
            text:
                'Street performers outside, great playlist inside. Peak social gravity! 🎵',
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ],
      ),
      Venue(
        id: 'neon-nook',
        name: 'The Neon Nook',
        address: '404 Cyber Lane, Neo-District',
        location: const LatLng(35.6580, 139.6950),
        vibes: [VibeTag.creativeFlow, VibeTag.socialBuzz, VibeTag.deepWork],
        crowdDensity: 0.78,
        checkinCount: 28,
        activeBeaconCount: 2,
        description:
            'High energy right now. Perfect for those who thrive in a busy environment.',
        distanceKm: 0.7,
        recentPulses: [
          StatusPulse(
            id: 'p3',
            authorName: 'Alex K.',
            authorInitials: 'AK',
            text:
                'The coffee is great, and there are plenty of outlets! Perfect for design work. ☕️⚡️',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          StatusPulse(
            id: 'p4',
            authorName: 'Lena M.',
            authorInitials: 'LM',
            text:
                'A bit loud near the counter, but the booths are quiet. Great playlist today! 🎶',
            createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
          ),
        ],
      ),
      Venue(
        id: 'zen-garden',
        name: 'Zen Garden Terrace',
        address: '88 Harmony Way, East Side',
        location: const LatLng(35.6610, 139.7060),
        vibes: [VibeTag.quietContemplation],
        crowdDensity: 0.25,
        checkinCount: 6,
        activeBeaconCount: 1,
        description:
            'A tranquil oasis. Perfect for journaling, meditation, or quiet reflection.',
        distanceKm: 1.2,
        recentPulses: [
          StatusPulse(
            id: 'p5',
            authorName: 'Yuki T.',
            authorInitials: 'YT',
            text: 'So peaceful here. The zen garden is beautiful at sunset 🌅',
            createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          ),
        ],
      ),
      Venue(
        id: 'the-grid',
        name: 'The Grid Cafe',
        address: '12 Circuit Street, Tech Quarter',
        location: const LatLng(35.6560, 139.7030),
        vibes: [VibeTag.deepWork, VibeTag.creativeFlow],
        crowdDensity: 0.55,
        checkinCount: 18,
        activeBeaconCount: 1,
        description:
            'Purpose-built for focused work. High-speed Wi-Fi and Pomodoro-friendly culture.',
        distanceKm: 0.9,
        recentPulses: [
          StatusPulse(
            id: 'p6',
            authorName: 'Dev P.',
            authorInitials: 'DP',
            text:
                'Perfect spot for sprints. Solid Wi-Fi and great cold brew 💻☕',
            createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
          ),
        ],
      ),
    ];
  }

  /// Active beacons (from Stitch MCP screen data: Active Beacons Feed)
  static List<Beacon> getBeacons() {
    return [
      Beacon(
        id: 'b1',
        hostName: 'Maya Chen',
        hostInitials: 'MC',
        hostLevel: 'Level 12 Guide',
        title: 'Sci-Fi Reading Circle',
        description:
            "Reading classic sci-fi at Central Park, join me! I'm currently halfway through 'Dune'. Bringing extra blankets. 📚",
        location: const LatLng(35.6590, 139.6940),
        locationName: 'Central Park, West Lawn',
        vibes: [VibeTag.quietContemplation, VibeTag.creativeFlow],
        maxCapacity: 4,
        currentCount: 2,
        expiresAt: DateTime.now().add(const Duration(hours: 2, minutes: 14)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 46)),
      ),
      Beacon(
        id: 'b2',
        hostName: 'Julian V.',
        hostInitials: 'JV',
        hostLevel: 'Community Architect',
        title: 'Sunset Photography Walk',
        description:
            'Sunset street photography walk through the Neon District. All camera types welcome, including phone shooters! 📸',
        location: const LatLng(35.6575, 139.6960),
        locationName: 'Neon District, Main Strip',
        vibes: [VibeTag.creativeFlow, VibeTag.socialBuzz],
        maxCapacity: 6,
        currentCount: 4,
        expiresAt: DateTime.now().add(const Duration(hours: 1, minutes: 42)),
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 18)),
      ),
      Beacon(
        id: 'b3',
        hostName: 'Sarah J.',
        hostInitials: 'SJ',
        hostLevel: 'Focus Lead',
        title: 'Silent Co-Working Sprint',
        description:
            "Silent co-working sprint at 'The Grid' cafe. Pomodoro sessions: 50min work / 10min break. High-speed Wi-Fi available. 💻",
        location: const LatLng(35.6560, 139.7030),
        locationName: 'The Grid Cafe, 2nd Floor',
        vibes: [VibeTag.deepWork],
        maxCapacity: 6,
        currentCount: 5,
        expiresAt: DateTime.now().add(const Duration(minutes: 58)),
        createdAt:
            DateTime.now().subtract(const Duration(hours: 2, minutes: 2)),
      ),
    ];
  }

  /// Current user profile (fallback for offline/testing)
  static UserProfile getUserProfile() {
    return const UserProfile(
      name: 'ThirdSpace User',
      initials: 'TS',
      checkinCount: 0,
      beaconsLit: 0,
      beaconsJoined: 0,
      eventsSignedUpFor: 0,
      eventsAttended: 0,
    );
  }
}
