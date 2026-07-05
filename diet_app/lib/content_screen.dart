import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'theme.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});
  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _articles = [];
  List<dynamic> _videos   = [];
  bool _loading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final arts  = await ApiService.getArticles();
      final vids  = await ApiService.getVideos();
      setState(() { _articles = arts; _videos = vids; });
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().length < 2) { _load(); return; }
    setState(() => _loading = true);
    try {
      final res = await ApiService.searchContent(q.trim());
      setState(() {
        _articles = List<dynamic>.from(res['articles'] ?? []);
        _videos   = List<dynamic>.from(res['videos']   ?? []);
      });
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Knowledge Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: kAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Articles'), Tab(text: 'Videos')],
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search articles & videos…',
              prefixIcon: const Icon(Icons.search, color: kPrimary),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onSubmitted: _doSearch,
            onChanged: (v) { if (v.isEmpty) _load(); },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kAccent2))
              : TabBarView(controller: _tabs, children: [
                  _ArticleList(articles: _articles),
                  _VideoList(videos: _videos),
                ]),
        ),
      ]),
    );
  }
}

class _ArticleList extends StatelessWidget {
  final List<dynamic> articles;
  const _ArticleList({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const Center(child: Text('No articles found.'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: articles.length,
      itemBuilder: (_, i) {
        final a = articles[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.article_outlined, color: kPrimary),
            ),
            title: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Text(a['summary'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.timer_outlined, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('${a['read_time_min']} min read', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _ArticleDetailScreen(articleId: a['id']))),
          ),
        );
      },
    );
  }
}

class _VideoList extends StatelessWidget {
  final List<dynamic> videos;
  const _VideoList({required this.videos});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const Center(child: Text('No videos found.'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final v = videos[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(v['thumbnail'] ?? '', width: 60, height: 45, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 60, height: 45, color: kPrimary.withOpacity(0.1),
                      child: const Icon(Icons.play_circle_outline, color: kPrimary))),
            ),
            title: Text(v['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Row(children: [
              Icon(Icons.play_circle_outline, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${v['duration_min']} min', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ]),
            trailing: const Icon(Icons.open_in_new, color: kAccent2, size: 18),
            onTap: () async {
              final url = Uri.parse(v['url'] ?? '');
              if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        );
      },
    );
  }
}

class _ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  const _ArticleDetailScreen({required this.articleId});
  @override
  State<_ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<_ArticleDetailScreen> {
  Map<String, dynamic>? _article;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ApiService.getArticle(widget.articleId).then((a) {
      if (mounted) setState(() { _article = a; _loading = false; });
    }).catchError((_) { if (mounted) setState(() => _loading = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
          title: Text(_article?['title'] ?? 'Article', style: const TextStyle(fontSize: 15))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent2))
          : _article == null
              ? const Center(child: Text('Failed to load article.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_article!['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimary)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.timer_outlined, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${_article!['read_time_min']} min read', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                    const SizedBox(height: 16),
                    Text(_article!['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.6)),
                    if (_article!['video_url'] != null) ...[ 
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(_article!['video_url']);
                          if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(_article!['video_title'] ?? 'Watch Video'),
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                      ),
                    ],
                    if ((_article!['references'] as List?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      Text('References', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 6),
                      for (final ref in _article!['references'] as List)
                        Text('• $ref', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ]),
                ),
    );
  }
}
