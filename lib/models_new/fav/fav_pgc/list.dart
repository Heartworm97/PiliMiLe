import 'package:PiliMiLe/models_new/fav/fav_pgc/new_ep.dart';
import 'package:PiliMiLe/pages/common/multi_select/base.dart';

class FavPgcItemModel with MultiSelectData {
  int? seasonId;
  String? title;
  String? cover;
  int? isFinish;
  String? badge;
  NewEp? newEp;
  String? renewalTime;
  String? progress;
  dynamic vodId;

  FavPgcItemModel({
    this.seasonId,
    this.title,
    this.cover,
    this.isFinish,
    this.badge,
    this.newEp,
    this.renewalTime,
    this.progress,
    this.vodId,
  });

  factory FavPgcItemModel.fromJson(
    Map<String, dynamic> json,
  ) => FavPgcItemModel(
    seasonId: json['season_id'] as int?,
    title: json['title'] as String?,
    cover: json['cover'] as String?,
    isFinish: json['is_finish'] as int?,
    badge: json['badge'] as String?,
    newEp: json['new_ep'] == null
        ? null
        : NewEp.fromJson(json['new_ep'] as Map<String, dynamic>),
    renewalTime: json['renewal_time'] as String?,
    progress: json['progress'] == '' ? null : json['progress'],
  );
}
