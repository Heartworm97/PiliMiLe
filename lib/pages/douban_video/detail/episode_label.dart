import 'package:PiliMiLe/models/douban/douban_detail.dart';

/// 集数显示文本：标准剧集/综艺统一显示「第X集」，电影等显示原始标题
String episodeLabel(DoubanEpisodeModel ep) {
  // 纯数字标题（如 "1", "01", "001"）→ 视为标准剧集
  if (RegExp(r'^\d+$').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 包含「第X集」或「第X期」→ 使用 nid 统一显示
  // 不限行首，兼容 "2025-01-01 第1期"、"第1期：嘉宾XXX"、"第1期上" 等变体
  if (RegExp(r'第\d+[集期]').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 日期格式标题（如 "2025-01-01"、"2025/01/01"）→ 视为综艺单期
  if (RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 英文集数格式（如 "EP01", "EP.01", "ep1"）
  if (RegExp(r'^EP\.?\s*\d+$', caseSensitive: false).hasMatch(ep.title)) {
    return '第${ep.nid}集';
  }
  // 电影等非标准剧集 → 显示原始标题（如「正片」「HD中字」）
  return ep.title;
}
