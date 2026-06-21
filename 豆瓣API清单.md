# 项目豆瓣 API 清单

## 1. 豆瓣影视搜索

```
GET https://m.douban.com/rexxar/api/v2/search
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `q` | query | 搜索关键词 |
| `start` | query | 分页起始位置，默认 0 |
| `count` | query | 每页条数，默认 20 |

**请求头：**
- `Referer: https://movie.douban.com/`
- `User-Agent`: 移动端 UA (`BrowserUa.mob`)
- `Accept: application/json, text/plain, */*`


---

## 2. 豆瓣热门影视

```
GET https://m.douban.com/rexxar/api/v2/subject/recent_hot/{kind}
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `kind` | path | `movie` 或 `tv` |
| `start` | query | 分页起始，默认 0 |
| `limit` | query | 返回条数，默认 6 |
| `category` | query | `热门` / `tv` / `show` |
| `type` | query | `全部` / `tv` / `tv_animation` / `show` |


---


## 3. 豆瓣图片 CDN 代理

豆瓣原始图片 URL 受防盗链保护：

```
https://img{1-9}.doubanio.com/.../{filename}
```

项目统一替换为社区 CDN 代理：

```
https://img.doubanio.cmliussss.net/view/photo/m_ratio_poster/public/{filename}
```

**代理域名 intermediate proxies（解析后直连 CDN）：**

| 代理 | 用途 |
|------|------|
| `https://api.zxki.cn/api/imgfdl?url=...` | 上游聚合结果中的豆瓣图片 |
| `https://4k.jdyx.pro/...` | 上游聚合结果中的豆瓣图片 |


---

## 4. 豆瓣影视详情

```
GET https://m.douban.com/rexxar/api/v2/movie/{id}
```

电影详情，返回演员、导演、类型、简介、预告片、获奖信息、评分详情等。

```
GET https://m.douban.com/rexxar/api/v2/tv/{id}
```

剧集/动漫/综艺详情，返回演员、导演、类型、简介、预告片、获奖信息、评分详情、集数等。

| 内容类型 | 端点后缀 | subtype 示例 | genres 示例 |
|------|------|------|------|
| 电影 | `/movie/{id}` | — | `['剧情','历史','战争']` |
| 电视剧 | `/tv/{id}` | `tv` | `['剧情','动作']` |
| 动漫 | `/tv/{id}` | `tv` | `['动作','动画','奇幻']` |
| 综艺 | `/tv/{id}` | `tv` | `['真人秀']` |

**通用响应字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 豆瓣 ID |
| `title` | string | 标题 |
| `type` | string | `movie` / `tv` |
| `subtype` | string | `tv` / 可能为空 |
| `year` | string | 年份 |
| `rating` | object | `{count, max, star_count, value}` |
| `card_subtitle` | string | 一句话信息 |
| `intro` | string | 简介 |
| `cover_url` | string | 封面图 |
| `cover` | object | 封面详情（含各尺寸） |
| `pic` | object | `{large, normal}` 海报图 |
| `actors` | list | 演员数组 `[{name}]` |
| `directors` | list | 导演数组 `[{name}]` |
| `genres` | list | 类型标签 |
| `countries` | list | 国家/地区 |
| `durations` | list | 片长 |
| `episodes_count` | int | 集数（仅 TV） |
| `episodes_info` | string | 集数描述 |
| `comment_count` | int | 评论数 |
| `review_count` | int | 长评数 |
| `trailers` | list | 预告片 `[{title, video_url, cover_url}]` |
| `honor_infos` | list | 获奖信息 `[{kind, rank, title}]` |
| `is_released` | bool | 是否已上映 |
| `is_show` | bool | 是否为综艺 |
| `pubdate` | list | 上映日期 |
| `vendors` | list | 播放平台 |
| `uri` | string | 豆瓣 URI 协议链接 |
| `url` | string | 豆瓣网页链接 |
| `sharing_url` | string | 分享链接 |


---