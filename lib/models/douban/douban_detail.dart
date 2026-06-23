/// 追剧集数
class DoubanEpisodeModel {
  final int nid;
  final String title;
  final String videoId;

  const DoubanEpisodeModel({
    required this.nid,
    required this.title,
    required this.videoId,
  });
}

/// 追剧播放线路
class DoubanSourceModel {
  final String key;
  final String name;
  final double sort;
  final String decodeStatus; // "1"=正常, 其他=维护中
  final int episodeCount;
  final List<DoubanEpisodeModel> episodes;

  const DoubanSourceModel({
    required this.key,
    required this.name,
    required this.sort,
    required this.decodeStatus,
    required this.episodeCount,
    required this.episodes,
  });
}

/// 追剧影片详情
class DoubanVodDetailModel {
  final String vodId;
  final String vodName;
  final String vodPic;
  final String vodRemarks;
  final String vodYear;
  final String vodArea;
  final String vodLang;
  final String vodActor;
  final String vodDirector;
  final String vodContent;
  final List<DoubanSourceModel> sources;

  const DoubanVodDetailModel({
    required this.vodId,
    required this.vodName,
    required this.vodPic,
    required this.vodRemarks,
    required this.vodYear,
    required this.vodArea,
    required this.vodLang,
    required this.vodActor,
    required this.vodDirector,
    required this.vodContent,
    required this.sources,
  });
}

/// 追剧解码结果（M3U8 播放地址）
class DoubanDecodeResultModel {
  final String url;
  final String source;
  final String episode;

  const DoubanDecodeResultModel({
    required this.url,
    required this.source,
    required this.episode,
  });

  factory DoubanDecodeResultModel.fromJson(Map<String, dynamic> json) {
    return DoubanDecodeResultModel(
      url: json['m3u8Url'] ?? json['url'] ?? '',
      source: json['source'] ?? '',
      episode: json['episode']?.toString() ?? '',
    );
  }
}
