import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/http/user.dart';
import 'package:PiliMiLe/models_new/follow/data.dart';
import 'package:PiliMiLe/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
