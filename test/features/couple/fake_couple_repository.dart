import 'package:ohana/features/couple/domain/couple_repository.dart';
import 'package:ohana/features/couple/domain/invite.dart';

class FakeCoupleRepository implements CoupleRepository {
  FakeCoupleRepository({required this.invite});

  Invite invite;

  /// When set, the matching call throws it once.
  Object? createCoupleError;
  Object? createInviteError;

  final List<String> createdWithTimezones = [];
  int inviteCalls = 0;

  @override
  Future<String> createCouple({required String timezone}) async {
    final error = createCoupleError;
    createCoupleError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    createdWithTimezones.add(timezone);
    return 'couple-1';
  }

  @override
  Future<Invite> createInvite() async {
    final error = createInviteError;
    createInviteError = null;
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
    inviteCalls++;
    return invite;
  }

  /// Errors thrown by successive joinCouple calls, first in first out.
  final List<Object> joinErrors = [];
  final List<({String code, bool leaveEmptySpace})> joinCalls = [];

  @override
  Future<String> joinCouple(String code, {bool leaveEmptySpace = false}) async {
    joinCalls.add((code: code, leaveEmptySpace: leaveEmptySpace));
    if (joinErrors.isNotEmpty) {
      Error.throwWithStackTrace(joinErrors.removeAt(0), StackTrace.current);
    }
    return 'couple-1';
  }

  CoupleSpace? couple;
  final List<DateTime> togetherSinceCalls = [];

  @override
  Future<CoupleSpace?> getMyCouple() async => couple;

  @override
  Future<void> setTogetherSince(DateTime date) async {
    togetherSinceCalls.add(date);
    couple = CoupleSpace(id: couple?.id ?? 'couple-1', togetherSince: date);
  }
}
