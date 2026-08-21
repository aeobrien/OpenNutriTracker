import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';

/// The Mac Mini could not be reached — no network, wrong address, or the server
/// is down. Work stays in the queue and is tried again.
class HouseholdUnreachable implements Exception {
  final String message;
  HouseholdUnreachable(this.message);

  /// The first half of the sentence a screen shows, so that every screen says
  /// the same true thing about the same fault.
  ///
  /// This exists because they did not. Every screen wrote "can't reach the
  /// Mac Mini" by hand, so a Mini that answered slowly was reported in
  /// the same words as a Mini that was not there — and on 19 August that
  /// sentence was shown to Aidan when the server had in fact answered him
  /// perfectly well, just not within the time the phone was willing to wait.
  String get headline => "Can't reach the Mac Mini";

  @override
  String toString() => 'HouseholdUnreachable: $message';
}

/// The Mac Mini was reachable and simply took longer than this call was willing
/// to wait.
///
/// Deliberately a *kind of* [HouseholdUnreachable] rather than a separate
/// exception: everything that queues, retries and holds work should treat it
/// exactly as it always did. The only thing that changes is what the person is
/// told, because "it is being slow" and "it is not there" are different facts
/// and only one of them is fixed by walking home.
class HouseholdTooSlow extends HouseholdUnreachable {
  final Duration waited;

  HouseholdTooSlow(this.waited)
      : super('it did not answer within ${waited.inSeconds} seconds');

  @override
  String get headline => 'The Mac Mini is taking too long to answer';
}

/// The Mini was reached and said no. Trying the identical request again will
/// get the identical answer, so the queue stops hammering it and keeps the item
/// with the reason attached rather than throwing the person's work away.
class HouseholdRefused implements Exception {
  final int status;
  final String message;
  HouseholdRefused(this.status, this.message);
  @override
  String toString() => 'HouseholdRefused($status): $message';
}

/// The phone's side of the /household/ endpoints on the Mac Mini.
class HouseholdApi {
  /// What an ordinary call is allowed to take. Reading a setting, saving a
  /// weight, registering the phone — all of them are a small amount of work on
  /// a machine in the next room, so a wait this long already means something is
  /// wrong and the person is better off being told.
  static const ordinary = Duration(seconds: 10);

  /// What reading a photographed packet is allowed to take.
  ///
  /// That call sends three photographs to a model and waits for it to read
  /// them. It is not the same kind of work as fetching a number, and giving it
  /// the same allowance was the fault: on 19 August the Mini read the packet
  /// and answered, and the phone had already given up and told Aidan it could
  /// not reach the house.
  static const readingALabel = Duration(minutes: 3);

  final String baseUrl;
  final http.Client _client;
  final _log = Logger('HouseholdApi');

  HouseholdApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  String get _base {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  /// Where a call is going, or a refusal to make it.
  ///
  /// Every address in this file went through `Uri.parse` and straight into the
  /// client. `Uri.parse` accepts almost anything — an empty string parses
  /// happily into a relative address — and the *client* is then the one to
  /// object, by throwing a programming error about a missing scheme rather than
  /// anything a screen was watching for. On 20 August 2026 that left a fresh
  /// install sitting on "Whose phone is this?" with a spinner that would never
  /// stop, because no address had ever been typed in.
  ///
  /// So the check happens here, once, and comes out as the same "can't reach
  /// it" every screen already knows how to show.
  Uri _address(String path) {
    final base = _base;
    if (base.isEmpty) {
      throw HouseholdUnreachable(
          'no address has been set for it yet — put one in Settings');
    }
    final uri = Uri.tryParse('$base$path');
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw HouseholdUnreachable(
          "its address doesn't look like one: '$base' (it needs the "
          'http:// on the front)');
    }
    return uri;
  }

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// What came back, or the right kind of complaint about it.
  ///
  /// **The code is read before the body, and that order is the whole point.**
  /// This used to parse first and ask questions afterwards, so a refusal that
  /// arrived as anything other than JSON came out as "could not reach the Mac
  /// Mini" — because failing to parse was the only thing that sentence was for.
  ///
  /// That is not a cosmetic difference. [Outbox.drain] stops at the first sign
  /// of unreachable, deliberately, so that fifty queued items do not collect
  /// fifty identical timeouts. A refusal mislabelled as unreachable therefore
  /// stops the queue rather than being recorded and stepped over — and on
  /// 21 August 2026 one queued item posting to a URL a since-replaced build had
  /// minted did exactly that. It was answered 405 as an HTML page, every
  /// attempt, for hours. Everything behind it — including a sentence somebody
  /// had just spoken onto their day — never left the phone, while the app said
  /// it could not reach a machine it was talking to perfectly well.
  ///
  /// So: a 4xx is a refusal whatever it is written in. Only a 5xx, or an answer
  /// that is somehow neither, is the Mini being unwell.
  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final code = response.statusCode;
    Map<String, dynamic>? body;
    try {
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) body = parsed;
    } on FormatException {
      body = null;
    }
    if (code >= 500) {
      throw HouseholdUnreachable('the server is having trouble ($code)');
    }
    if (code >= 400) {
      // Its own words if it gave any, and the number if it did not. The number
      // matters: it is what tells whoever reads the queue later that this item
      // is asking for something the server will never agree to.
      throw HouseholdRefused(
          code, (body?['error'] ?? 'it refused, and did not say why ($code)')
              .toString());
    }
    if (body == null) {
      throw HouseholdUnreachable(
          'the server answered with something that was not JSON');
    }
    return body;
  }

  Future<Map<String, dynamic>> get(String path, {Duration? timeout}) async {
    final limit = timeout ?? ordinary;
    try {
      final r = await _client
          .get(_address(path), headers: _headers)
          .timeout(limit);
      return _decode(r);
    } on TimeoutException {
      throw HouseholdTooSlow(limit);
    } on http.ClientException catch (e) {
      throw HouseholdUnreachable(e.message);
    }
  }

  /// The one way anything is sent to the server. The outbox calls this and
  /// nothing else does, so there is a single place where "sent" is decided.
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {Duration? timeout}) async {
    final limit = timeout ?? ordinary;
    try {
      final r = await _client
          .post(_address(path), headers: _headers, body: jsonEncode(body))
          .timeout(limit);
      return _decode(r);
    } on TimeoutException {
      throw HouseholdTooSlow(limit);
    } on http.ClientException catch (e) {
      throw HouseholdUnreachable(e.message);
    }
  }

  /// What understanding a spoken sentence is allowed to take.
  ///
  /// Longer than an ordinary call for the same reason reading a photographed
  /// packet is: transcribing a recording and then working out what it means is
  /// two pieces of real work, not fetching a number. Shorter than reading a
  /// label because the row is already on the day either way — nothing is lost
  /// by giving up, it just stays as the words the person said until the next
  /// try.
  static const workingOutWhatYouSaid = Duration(seconds: 90);

  /// Ask the Mac Mini what a row somebody spoke actually was.
  ///
  /// [clip] is the recording, when there is one. Sending it as a file rather
  /// than as text is the whole point: the transcriber lives on the Mini, is the
  /// same one the kitchen panel's Talk button has used for years, and this
  /// phone has no business growing a second one.
  ///
  /// [version] is what the row was at when this was asked. It travels so the
  /// answer can be thrown away if the person corrects the row while the Mini is
  /// still thinking — see the server's settle_entry.
  Future<Map<String, dynamic>> said({
    required String clientId,
    required int version,
    String? text,
    File? clip,
  }) async {
    if (clip == null) {
      return post(
          '/household/said',
          {
            'client_id': clientId,
            'version': version,
            if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
          },
          timeout: workingOutWhatYouSaid);
    }
    final request = http.MultipartRequest(
        'POST', _address('/household/said'))
      ..fields['client_id'] = clientId
      ..fields['version'] = '$version'
      ..files.add(await http.MultipartFile.fromPath('audio', clip.path));
    if (text != null && text.trim().isNotEmpty) {
      request.fields['text'] = text.trim();
    }
    try {
      final streamed =
          await _client.send(request).timeout(workingOutWhatYouSaid);
      return _decode(await http.Response.fromStream(streamed));
    } on TimeoutException {
      throw HouseholdTooSlow(workingOutWhatYouSaid);
    } on http.ClientException catch (e) {
      throw HouseholdUnreachable(e.message);
    }
  }

  Future<List<HouseholdPerson>> people() async {
    final body = await get('/household/people');
    return (body['people'] as List)
        .map((p) => HouseholdPerson.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerDevice(String deviceId, int personId) async {
    await post('/household/device',
        {'device_id': deviceId, 'person_id': personId});
    _log.info('[HOUSE] device $deviceId registered to person $personId');
  }

  /// Whose phone the *server* thinks this is. Asked rather than asserted: the
  /// server holds the answer, the phone does not send one and hope.
  Future<int> deviceOwner(String deviceId) async {
    final body = await get('/household/device/$deviceId');
    return body['person_id'] as int;
  }

  Future<PersonSettings> settings(int personId) async {
    final body = await get('/household/settings/$personId');
    return PersonSettings.fromJson(body['settings'] as Map<String, dynamic>);
  }

  Future<PersonSettings> updateSettings(int personId, Map<String, dynamic> changes) async {
    final body = await post('/household/settings/$personId', changes);
    return PersonSettings.fromJson(body['settings'] as Map<String, dynamic>);
  }

  /// What the household knows about this person for the app's own setup —
  /// their age, height, weight and what they are trying to do — or null when
  /// it has never been told.
  ///
  /// Null and "told only half of it" are the same answer here, and that is the
  /// server's rule rather than this method's: a half-known person would let the
  /// app skip its setup and then work a daily calorie target out of numbers it
  /// never had.
  Future<Map<String, dynamic>?> profileFor(int personId) async {
    final body = await get('/household/settings/$personId');
    final p = body['profile'];
    return p == null ? null : (p as Map<String, dynamic>);
  }

  /// Hand the household what setup just asked the person. Sent on the settings
  /// route because that is where it is read back from.
  Future<void> rememberProfile(int personId, Map<String, dynamic> profile) async {
    await post('/household/settings/$personId', {'profile': profile});
  }

  /// Everything this person has weighed in at. Asked for regardless of the
  /// weight-tracking switch — the switch decides what is shown, never what is
  /// kept.
  Future<List<Map<String, dynamic>>> weights(int personId) async {
    final body = await get('/household/weights/$personId');
    return (body['weights'] as List).cast<Map<String, dynamic>>();
  }

  /// The same history, with the trend running through it and how much it has
  /// moved in a week. One call rather than two: it is the same row of the same
  /// table and splitting it would let the readings and the line drawn through
  /// them arrive from two different moments.
  Future<Map<String, dynamic>> weightHistory(int personId) =>
      get('/household/weights/$personId');

  /// The household's own food list.
  ///
  /// One call with three optional narrowings, matching the server: [q] is a
  /// search over names and brands, [barcode] is an exact lookup, and
  /// [forPerson] puts the list in that person's order — what they actually eat,
  /// first.
  ///
  /// [forPerson] is sent rather than inferred from the handset because the
  /// phone can be handed over: the list should follow whoever the app says it
  /// belongs to, not the device.
  Future<List<HouseholdFood>> foods({
    String? q,
    String? barcode,
    int? forPerson,
  }) async {
    final query = <String, String>{
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (barcode != null && barcode.trim().isNotEmpty)
        'barcode': barcode.trim(),
      if (forPerson != null) 'for': forPerson.toString(),
    };
    final path = query.isEmpty
        ? '/household/foods'
        : '/household/foods?${Uri(queryParameters: query).query}';
    final body = await get(path);
    return (body['foods'] as List)
        .map((f) => HouseholdFood.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  /// Ask the Mac Mini to go and look a packet up on the web.
  ///
  /// Returns candidates, not foods: nothing is saved anywhere by this call, at
  /// either end. A person picks one, checks it, and only then does it become
  /// one of the household's foods — which is the same shape as reading a label
  /// off a photograph, and for the same reason.
  ///
  /// An empty list is a normal answer. So is a Mac Mini too old to know
  /// this route at all, which is why the caller treats a failure and a
  /// nothing-found the same way.
  Future<List<Map<String, dynamic>>> findFood(String name,
      {Duration? timeout}) async {
    final body = await post('/household/food/find', {'name': name},
        timeout: timeout ?? const Duration(seconds: 45));
    return [
      for (final c in (body['candidates'] as List? ?? const []))
        c as Map<String, dynamic>,
    ];
  }

  Future<Map<String, dynamic>> day(int personId, String day) async {
    return get('/household/day/$personId/$day');
  }

  /// One person's week, assembled on the server. [start] names the Monday;
  /// leaving it off lets the Mac Mini decide which week today is in,
  /// so the two handsets and the panel cannot disagree about it.
  Future<Map<String, dynamic>> week(int personId, {String? start}) async {
    final query = start == null ? '' : '?start=$start';
    return get('/household/week/$personId$query');
  }

  /// The household's planned week — everybody's, not one person's. [start]
  /// names the Monday; leaving it off lets the Mac Mini decide.
  ///
  /// Separate from [week] on purpose. A person's week answers "what am I
  /// eating and what does it come to"; this answers "what is the house
  /// planning" — the same rows, but with everyone's share and everyone's
  /// answer attached, which is what you need in front of you to change the
  /// plan rather than to read it.
  Future<Map<String, dynamic>> plan({String? start}) async {
    final query = start == null ? '' : '?start=$start';
    return get('/household/plan$query');
  }

  /// The meals the house already has, for the planner to choose from.
  ///
  /// [q] narrows by name. The list is deliberately the kitchen panel's own —
  /// a planned meal that is only a typed name has no recipe behind it, so no
  /// calories for the week and no ingredients for the shopping list.
  Future<List<Map<String, dynamic>>> meals({String? q}) async {
    final trimmed = (q ?? '').trim();
    final path = trimmed.isEmpty
        ? '/household/meals'
        : '/household/meals?${Uri(queryParameters: {'q': trimmed}).query}';
    final body = await get(path);
    return [
      for (final m in (body['meals'] as List? ?? const []))
        m as Map<String, dynamic>,
    ];
  }

  /// Put one meal on one day. One call per meal, matching the server, so an
  /// interrupted session leaves exactly the meals that landed.
  Future<int> planAdd({
    required String date,
    int? mealId,
    String? title,
    String? actor,
  }) async {
    final body = await post('/household/plan/add', {
      'date': date,
      if (mealId != null) 'meal_id': mealId,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (actor != null) 'actor': actor,
    });
    return body['plan_id'] as int;
  }

  /// Take one meal off the plan. Anything already logged against it stays
  /// logged — the plan is what is intended, the ledger is what happened.
  Future<void> planRemove(int planId) async {
    await post('/household/plan/$planId/remove', const {});
  }
}
