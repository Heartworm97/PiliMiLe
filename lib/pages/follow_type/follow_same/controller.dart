import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/http/user.dart';
import 'package:PiliMiLe/models_new/follow/data.dart';
import 'package:PiliMiLe/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
