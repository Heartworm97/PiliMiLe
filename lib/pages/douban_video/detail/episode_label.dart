import 'package:PiliMiLe/models/douban/douban_detail.dart';

/// 集数显示文本：标准剧集/综艺统一显示「第X集」，电影等显示原始标题
String episodeLabel(DoubanEpisodeModel ep) {
  // 标准剧集格式「第X集」→ 使用 nid 统一显示
  if (RegExp(r'^第\d+集$').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 综艺格式「第X期」（含「第X期上/下」等后缀）→ 使用 nid 统一显示
  if (RegExp(r'^第\d+期').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 纯数字标题（如 "1", "01", "001"）→ 视为标准剧集
  if (RegExp(r'^\d+$').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 电影等非标准剧集 → 显示原始标题（如「正片」「HD中字」）
  return ep.title;
}
