import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'app_theme.dart';

class _Post {
  final String id, author, initial, animal, emoji, body;
  int likes;
  final int comments;
  final DateTime at;
  bool liked;
  _Post({required this.id, required this.author, required this.initial,
    required this.animal, required this.emoji, required this.body,
    required this.likes, required this.comments, required this.at, this.liked = false});
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _search = TextEditingController();
  String _q = '';

  final _posts = [
    _Post(id:'1', author:'Lucas M.', initial:'L', animal:'Pogona', emoji:'🦎',
        body:'Mon pogona adore sa nouvelle lampe UVB. Température stabilisée à 32°C côté chaud, 26°C côté froid.',
        likes:24, comments:5, at: DateTime.now().subtract(const Duration(hours:2))),
    _Post(id:'2', author:'Marie L.', initial:'M', animal:'Python royal', emoji:'🐍',
        body:'Quelle humidité recommandez-vous pour un python royal en mue ? Mon boîtier indique 68%.',
        likes:8, comments:12, at: DateTime.now().subtract(const Duration(hours:5))),
    _Post(id:'3', author:'Thomas B.', initial:'T', animal:'Gecko léopard', emoji:'🦖',
        body:'Le scénario "mode nuit" fonctionne parfaitement — la température descend doucement à 22°C à 20h pile.',
        likes:41, comments:9, at: DateTime.now().subtract(const Duration(hours:8))),
    _Post(id:'4', author:'Sophie R.', initial:'S', animal:'Caméléon', emoji:'🦜',
        body:'Mon brumisateur tourne 3x par jour pour maintenir le gradient d\'humidité nécessaire aux caméléons.',
        likes:17, comments:3, at: DateTime.now().subtract(const Duration(days:1))),
    _Post(id:'5', author:'Alex D.', initial:'A', animal:'Tortue', emoji:'🐢',
        body:'Première hibernation supervisée avec des capteurs. Température maintenue entre 4°C et 8°C en cave.',
        likes:33, comments:7, at: DateTime.now().subtract(const Duration(days:2))),
  ];

  static const _tips = [
    ('Gradient thermique', 'Prévois 8°C minimum entre la zone chaude et froide pour permettre la thermorégulation.'),
    ('Humidité & mue', 'Monte à 80–90% d\'humidité pendant les mues pour éviter les rétentions cutanées.'),
    ('Cycle lumière', 'Reproduis le cycle naturel de l\'espèce — 12h/12h en été, 10h/14h en hiver.'),
    ('Sécurité électrique', 'Prises étanches obligatoires en zones humides. Thermostat de sécurité anti-surchauffe.'),
    ('Supplémentation', 'Calcium + D3 sur les proies 2× par semaine pour les lézards insectivores.'),
  ];

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); _search.dispose(); super.dispose(); }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}min';
    if (d.inHours < 24)  return '${d.inHours}h';
    return '${d.inDays}j';
  }

  void _newPost() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Handle(),
          Text('Nouveau post', style: T.t17.copyWith(color: T.textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl, maxLines: 4, autofocus: true,
            style: const TextStyle(color: T.textPrimary, fontSize: 15),
            decoration: const InputDecoration(hintText: 'Partage ton expérience…'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              setState(() => _posts.insert(0, _Post(
                id: DateTime.now().toString(), author: 'Moi', initial: 'M',
                animal: 'Mon animal', emoji: '🦎', body: ctrl.text.trim(),
                likes: 0, comments: 0, at: DateTime.now(),
              )));
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: T.green, foregroundColor: T.bg,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _posts.where((p) =>
      _q.isEmpty || p.body.toLowerCase().contains(_q.toLowerCase()) ||
      p.author.toLowerCase().contains(_q.toLowerCase())).toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true, backgroundColor: T.bg, surfaceTintColor: Colors.transparent,
            title: const Text('Communauté'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _q = v),
                    style: const TextStyle(color: T.textPrimary, fontSize: 14),
                    backgroundColor: T.elevated,
                    placeholder: 'Rechercher…',
                  ),
                ),
                TabBar(
                  controller: _tab,
                  indicatorColor: T.green,
                  labelColor: T.textPrimary,
                  unselectedLabelColor: T.textSecondary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: 'Publications'), Tab(text: 'Conseils')],
                ),
              ]),
            ),
          ),
        ],
        body: TabBarView(controller: _tab, children: [
          // Publications
          filtered.isEmpty
              ? Center(child: Text('Aucun résultat', style: T.t14.copyWith(color: T.textSecondary)))
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
                  itemBuilder: (_, i) => _PostRow(
                    post: filtered[i], ago: _ago(filtered[i].at),
                    onLike: () => setState(() {
                      filtered[i].liked = !filtered[i].liked;
                      filtered[i].likes += filtered[i].liked ? 1 : -1;
                    }),
                  ),
                ),
          // Conseils
          ListView.separated(
            itemCount: _tips.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
            itemBuilder: (_, i) => _TipRow(title: _tips[i].$1, body: _tips[i].$2),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newPost, mini: true,
        backgroundColor: T.green, foregroundColor: T.bg,
        child: const Icon(Icons.edit_outlined, size: 18),
      ),
    );
  }
}

class _PostRow extends StatelessWidget {
  final _Post post;
  final String ago;
  final VoidCallback onLike;
  const _PostRow({required this.post, required this.ago, required this.onLike});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Author row
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: T.elevated, shape: BoxShape.circle),
          child: Center(child: Text(post.initial,
              style: T.t14.copyWith(color: T.green, fontWeight: FontWeight.w600))),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(post.author, style: T.t13.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Text('·', style: T.t13.copyWith(color: T.textTertiary)),
            const SizedBox(width: 6),
            Text(ago, style: T.t13.copyWith(color: T.textSecondary)),
          ]),
          Text('${post.emoji} ${post.animal}', style: T.t12.copyWith(color: T.textSecondary)),
        ])),
      ]),
      const SizedBox(height: 10),
      // Body
      Text(post.body, style: T.t14.copyWith(color: T.textPrimary, height: 1.5)),
      const SizedBox(height: 12),
      // Actions
      Row(children: [
        GestureDetector(
          onTap: onLike,
          child: Row(children: [
            Icon(post.liked ? Icons.favorite : Icons.favorite_border,
                color: post.liked ? const Color(0xFFF87171) : T.textSecondary, size: 16),
            const SizedBox(width: 4),
            Text('${post.likes}', style: T.t13.copyWith(
                color: post.liked ? const Color(0xFFF87171) : T.textSecondary)),
          ]),
        ),
        const SizedBox(width: 20),
        Icon(Icons.chat_bubble_outline, color: T.textSecondary, size: 16),
        const SizedBox(width: 4),
        Text('${post.comments}', style: T.t13.copyWith(color: T.textSecondary)),
      ]),
    ]),
  );
}

class _TipRow extends StatefulWidget {
  final String title, body;
  const _TipRow({required this.title, required this.body});
  @override
  State<_TipRow> createState() => _TipRowState();
}

class _TipRowState extends State<_TipRow> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(widget.title,
              style: T.t14.copyWith(color: T.textPrimary, fontWeight: FontWeight.w500))),
          Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: T.textTertiary, size: 18),
        ]),
        if (_open) ...[
          const SizedBox(height: 8),
          Text(widget.body, style: T.t14.copyWith(color: T.textSecondary, height: 1.5)),
        ],
      ]),
    ),
  );
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Container(
    width: 32, height: 4, margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: T.border, borderRadius: BorderRadius.circular(2)),
  ));
}
