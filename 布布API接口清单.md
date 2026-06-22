# 上游（追剧/豆瓣/镜像站）API 接口清单

## 一、获取上游地址

| 文件 | 行号 | 常量/方法 | 地址/端点 | 说明 |
|------|------|-----------|-----------|------|
| [douban.dart](lib/http/douban.dart) | 38–43 | `_upstreamMirrors` | 4个硬编码镜像域名 | 上游镜像站列表，播放/搜索/解码的代理源站 |
| [douban.dart](lib/http/douban.dart) | 51–79 | `_activeHost` / `_switchToNextHost()` / `_markHostAlive()` | — | 当前活跃线路host getter + 切换/标记逻辑，索引缓存于 `upstreamMirrorIndex` |
| [douban.dart](lib/http/douban.dart) | 32–33 | `_doubanHost` / `_picCdnHost` | `https://m.douban.com` / `img.doubanio.cmliussss.net` | 豆瓣官方域名 + 图片反盗链CDN代理 |
| [douban.dart](lib/http/douban.dart) | 96–153 | `_upstreamGet()` / `_upstreamPost()` | `$_activeHost$path` | 带线路自动切换的上游 GET/POST 请求封装 |
| [wasm_bridge.dart](lib/services/wasm_bridge.dart) | 187–220 | `_resolveWasmUrl()` | 动态解析 | 从上游首页 HTML → JS 入口 → `.wasm` 文件名，拼接完整 WASM 下载 URL |

## 二、搜索

| 文件 | 行号 | 方法 | 端点 | 说明 |
|------|------|------|------|------|
| [douban.dart](lib/http/douban.dart) | 342–403 | `DoubanHttp.searchVod({keyword, page})` | `POST /api.php/web/search/index` | 上游镜像站搜索影片，参数 wd/page/limit，返回影片列表 |
| [search_panel/controller.dart](lib/pages/search_panel/controller.dart) | — | `onSearch({type: 'douban'})` | → `DoubanHttp.searchVod()` | 追剧搜索入口 |

## 三、播放

| 文件 | 行号 | 方法 | 端点 | 说明 |
|------|------|------|------|------|
| [douban.dart](lib/http/douban.dart) | 565–639 | `DoubanHttp.decodeVod({vodId, sid, nid, videoId})` | — | 追剧视频解码入口：若 videoId 以 `.m3u8` 结尾则直链播放；否则走 WASM 编解码链路 |
| [upstream_decoder.dart](lib/services/upstream_decoder.dart) | 28–111 | `UpstreamDecoder.decode({upstreamHost, videoId, siteKey})` | `POST /api.php/web/decode/url` | WASM 解码链路：protobuf 编码请求 → POST 上游解码接口 → 解析响应获取 M3U8 URL |
| [wasm_bridge.dart](lib/services/wasm_bridge.dart) | 60–90 | `WasmBridge.createDecodeRequest()` / `WasmBridge.parseDecodeResponse()` | WebView JS 桥接 | 调用 WASM 模块的 `create_decode_request` / `parse_decode_response` 完成编解码 |
| [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) | 243–291 | `_decodeAndPlay({sid, nid, videoId})` | → `DoubanHttp.decodeVod()` | 追剧播放：解码获取 M3U8 → 初始化播放器 |

## 四、线路

| 文件 | 行号 | 方法 | 端点 | 说明 |
|------|------|------|------|------|
| [douban.dart](lib/http/douban.dart) | 48–79 | `_switchToNextHost()` / `_markHostAlive()` / `_activeHost` | — | 上游镜像站线路切换（轮询4个域名），当前线路索引缓存在 `upstreamMirrorIndex` |
| [douban.dart](lib/http/douban.dart) | 408–506 | `DoubanHttp.getVodDetail({vodId})` | `POST /api.php/web/vod/get_detail` | 获取影片详情，解析 `vod_play_from`（线路列表）和 `vod_play_url`（各线路集数），构建 `DoubanSourceModel` 列表 |
| [douban.dart](lib/http/douban.dart) | 509–560 | `DoubanHttp._fetchAggregateSources({vodId})` | `GET /api.php/web/internal/search_aggregate` | 获取站外聚合线路（其他源站），与内置线路合并展示 |
| [douban.dart](lib/http/douban.dart) | 475–483 | 线路排序逻辑 | — | 内置线路排前（按 sort 降序），聚合线路排后 |
| [douban.dart](lib/http/douban.dart) | 294–326 | `_applyFormattedTitles()` | — | `decodeStatus != '1'` 的维护线路排到最右边并标记"维护" |
| [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) | 191–201 | `switchSource(key)` | → `_decodeAndPlay()` | 切换播放线路，取该线路第一集进行解码播放 |

## 五、集数

| 文件 | 行号 | 方法 | 端点 | 说明 |
|------|------|------|------|------|
| [douban.dart](lib/http/douban.dart) | 437–472 | `getVodDetail()` 内集数解析 | 来自上游 `vod_play_url` 字段 | 解析规则：`$$$` 分隔各线路 → `#` 分隔各集 → `$` 分隔集标题和 videoId |
| [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) | 204–229 | `onTapEpisode(nid, videoId)` | → `_decodeAndPlay()` | 点击指定集数进行解码播放 |
| [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) | 204–229 | `playPrev()` / `playNext()` | → `onTapEpisode()` | 上一集/下一集切换 |
| [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) | 191–201 | `toggleEpOrder()` | — | 切换集数显示顺序（正序/倒序） |

## 汇总

| 分类 | 接口/方法数 | 核心文件 |
|------|------------|----------|
| 上游地址 | 5 | [douban.dart](lib/http/douban.dart), [wasm_bridge.dart](lib/services/wasm_bridge.dart) |
| 搜索 | 2 | [douban.dart](lib/http/douban.dart), [search_panel/controller.dart](lib/pages/search_panel/controller.dart) |
| 播放 | 4 | [douban.dart](lib/http/douban.dart), [upstream_decoder.dart](lib/services/upstream_decoder.dart), [wasm_bridge.dart](lib/services/wasm_bridge.dart) |
| 线路 | 6 | [douban.dart](lib/http/douban.dart), [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) |
| 集数 | 4 | [douban.dart](lib/http/douban.dart), [douban_video/detail/controller.dart](lib/pages/douban_video/detail/controller.dart) |

## 核心链路

```
搜索 → searchVod() → /api.php/web/search/index
详情 → getVodDetail() → /api.php/web/vod/get_detail  （线路 + 集数）
聚合 → _fetchAggregateSources() → /api.php/web/internal/search_aggregate
解码 → decodeVod() → UpstreamDecoder.decode() → /api.php/web/decode/url  （WASM protobuf）
播放 → M3U8 直链
```
