import 'package:flutter/material.dart';
import 'api_service.dart';
import 'theme.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<dynamic> _posts = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await ApiService.getForumPosts();
      setState(() => _posts = posts);
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  void _showNewPost() {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login to post in the forum.')));
      return;
    }
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();
    String category = 'general';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(builder: (ctx, setS) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('New Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 16),
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: ['general', 'diet', 'exercise', 'vitamins', 'cholesterol', 'mental_health']
                .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setS(() => category = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.trim().length < 5 || bodyCtrl.text.trim().length < 10) return;
              Navigator.pop(ctx);
              await ApiService.createForumPost(titleCtrl.text.trim(), bodyCtrl.text.trim(), category);
              _load();
            },
            child: const Text('Post'),
          )),
          const SizedBox(height: 16),
        ])),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Community Forum', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPost,
        backgroundColor: kPrimary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent2))
          : _posts.isEmpty
              ? const Center(child: Text('No posts yet. Be the first to share!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _posts.length,
                  itemBuilder: (_, i) {
                    final p = _posts[i] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text(p['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(p['username'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 12),
                            Icon(Icons.chat_bubble_outline, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${p['reply_count'] ?? 0} replies', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text(p['category'] ?? '', style: const TextStyle(fontSize: 10, color: kPrimary)),
                            ),
                          ]),
                        ]),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => _PostDetailScreen(post: p))).then((_) => _load()),
                      ),
                    );
                  },
                ),
    );
  }
}

class _PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostDetailScreen({required this.post});
  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  List<dynamic> _replies = [];
  final _replyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadReplies(); }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _loadReplies() async {
    setState(() => _loading = true);
    try {
      final replies = await ApiService.getForumReplies(widget.post['id'] as int);
      setState(() => _replies = replies);
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().length < 2 || ApiService.token == null) return;
    await ApiService.createForumReply(widget.post['id'] as int, _replyCtrl.text.trim());
    _replyCtrl.clear();
    _loadReplies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(widget.post['title'] ?? '', style: const TextStyle(fontSize: 15)),
        backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.post['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary)),
              const SizedBox(height: 8),
              Text(widget.post['body'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 8),
              Text('— ${widget.post['username']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Replies (${_replies.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 8),
          if (_loading) const Center(child: CircularProgressIndicator(color: kAccent2)),
          for (final r in _replies) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kPrimary)),
                const SizedBox(height: 4),
                Text(r['body'] ?? '', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ],
        ])),
        if (ApiService.token != null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: Row(children: [
              Expanded(child: TextField(
                controller: _replyCtrl,
                decoration: InputDecoration(
                  hintText: 'Write a reply…',
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              )),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendReply,
                icon: const Icon(Icons.send, color: kPrimary),
                style: IconButton.styleFrom(backgroundColor: kPrimary.withOpacity(0.1)),
              ),
            ]),
          ),
      ]),
    );
  }
}
