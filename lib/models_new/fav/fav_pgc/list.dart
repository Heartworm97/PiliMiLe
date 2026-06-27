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
  String? progressTime;
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
    this.progressTime,
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

  /// 进度文本中时间补零（"第5集 5:16" → "第5集 05:16"）
  String? get formattedProgress {
    if (progress == null) return null;
    return progress!
        .replaceAllMapped(
          RegExp(r'\b(\d+):(\d{2}):(\d{2})\b'),
          (m) => '${m[1]!.padLeft(2, '0')}:${m[2]}:${m[3]}',
        )
        .replaceAllMapped(
          RegExp(r'\b(\d+):(\d{2})\b(?!:\d)'),
          (m) => '${m[1]!.padLeft(2, '0')}:${m[2]}',
        );
  }
}
