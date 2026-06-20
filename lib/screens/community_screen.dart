import 'package:flutter/material.dart';
import 'app_theme.dart';

class _Post {
  final String id, author, initial, body;
  int likes; final int comments; final DateTime at; bool liked;
  _Post({required this.id, required this.author, required this.initial,
    required this.body, required this.likes, required this.comments,
    required this.at, this.liked = false});
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _posts = [
    _Post(id:'1', author:'lila_terraria', initial:'L',
        body:'Mon dendrobate adore sa nouvelle plante 🌿',
        likes:42, comments:8, at: DateTime.now().subtract(const Duration(hours:2))),
    _Post(id:'2', author:'gecko_fanatic', initial:'G',
        body:'Setup complet pour mon léopard gecko : sonde DS18B20 + DHT22. Résultats bluffants !',
        likes:31, comments:5, at: DateTime.now().subtract(const Duration(hours:6))),
    _Post(id:'3', author:'reptile_yann', initial:'R',
        body:'Premier terrarium connecté en place. La brumisation automatique c\'est une révolution.',
        likes:18, comments:3, at: DateTime.now().subtract(const Duration(days:1))),
  ];

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24)   return 'il y a ${d.inHours} h';
    return 'il y a ${d.inDays} j';
  }

  void _newPost() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: T.border, borderRadius: BorderRadius.circular(2)))),
          Text('Nouveau post', style: T.serif(20)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 4, autofocus: true,
              style: T.t15.copyWith(color: T.textPrimary),
              decoration: const InputDecoration(hintText: 'Partage ton expérience…')),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => _posts.insert(0, _Post(id: DateTime.now().toString(),
                  author: 'Moi', initial: 'M', body: ctrl.text.trim(), likes: 0, comments: 0, at: DateTime.now())));
              Navigator.pop(ctx);
            },
            child: Container(height: 50,
                decoration: BoxDecoration(color: T.greenBtn, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('Publier', style: T.t16.copyWith(color: const Color(0xFF0A1A0F), fontWeight: FontWeight.w700)))),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('COMMUNAUTÉ', style: T.t11.copyWith(color: T.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Feed', style: T.serif(30)),
                ])),
                GestureDetector(
                  onTap: _newPost,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: T.greenBtn, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Color(0xFF0A1A0F), size: 22),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: _posts.length,
                itemBuilder: (_, i) => _PostCard(
                  post: _posts[i], ago: _ago(_posts[i].at),
                  onLike: () => setState(() { _posts[i].liked = !_posts[i].liked; _posts[i].likes += _posts[i].liked ? 1 : -1; }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final _Post post; final String ago; final VoidCallback onLike;
  const _PostCard({required this.post, required this.ago, required this.onLike});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: T.card2, borderRadius: BorderRadius.circular(18), border: Border.all(color: T.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: T.green.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text(post.initial, style: T.t16.copyWith(color: T.green, fontWeight: FontWeight.w700)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.author, style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w600)),
            Text(ago, style: T.t12.copyWith(color: T.textSecondary)),
          ]),
        ]),
      ),
      // Photo placeholder
      Container(
        width: double.infinity, height: 220,
        color: T.card,
        child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF2A3A2F), size: 48),
      ),
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: onLike,
              child: Row(children: [
                Icon(post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? const Color(0xFFF87171) : T.textSecondary, size: 20),
                const SizedBox(width: 4),
                Text('${post.likes}', style: T.t14.copyWith(color: post.liked ? const Color(0xFFF87171) : T.textSecondary)),
              ]),
            ),
            const SizedBox(width: 16),
            Row(children: [
              const Icon(Icons.chat_bubble_outline, color: T.textSecondary, size: 18),
              const SizedBox(width: 4),
              Text('${post.comments}', style: T.t14.copyWith(color: T.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 8),
          Text(post.body, style: T.t14.copyWith(color: T.textPrimary, height: 1.5)),
        ]),
      ),
    ]),
  );
}
