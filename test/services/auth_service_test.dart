import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:jebbo/services/auth_service.dart';

User _user(String id, [Map<String, dynamic> meta = const {}]) => User(
  id: id,
  appMetadata: const {},
  userMetadata: meta,
  aud: 'authenticated',
  email: '$id@example.com',
  createdAt: '2026-10-12T00:00:00Z',
);

void main() {
  final auth = AuthService.instance;
  tearDown(() => auth.setUser(null));

  test('maps Google/Apple metadata, preferring full_name and avatar_url', () {
    auth.setUser(
      _user('a', {
        'full_name': 'Ada Lovelace',
        'name': 'ada',
        'avatar_url': 'https://img/a.png',
        'picture': 'https://img/other.png',
      }),
    );
    var s = auth.currentSession!;
    expect(
      [s.userId, s.email, s.name, s.pictureUrl],
      ['a', 'a@example.com', 'Ada Lovelace', 'https://img/a.png'],
    );

    auth.setUser(
      _user('b', {
        'name': 'Bob',
        'picture': 'https://img/b.png',
        'full_name': 42,
      }),
    );
    s = auth.currentSession!;
    expect([s.name, s.pictureUrl], ['Bob', 'https://img/b.png']);

    auth.setUser(_user('c'));
    expect(
      [auth.currentSession!.name, auth.currentSession!.pictureUrl],
      [null, null],
    );
  });

  test(
    'notifies only when the user changes, so token refreshes never re-run AuthGate sign-in',
    () {
      var notified = 0;
      void listener() => notified++;
      auth.session.addListener(listener);
      addTearDown(() => auth.session.removeListener(listener));

      auth.setUser(_user('a'));
      expect(notified, 1);

      // Same user again (token refresh, Apple name saved): profile updates silently.
      auth.setUser(_user('a', {'full_name': 'Ada'}));
      expect(notified, 1);
      expect(auth.currentSession!.name, 'Ada');

      auth.setUser(_user('b'));
      expect(notified, 2);
      auth.setUser(null);
      expect(notified, 3);
      expect(auth.currentSession, isNull);
    },
  );
}
