import 'package:flutter/material.dart';

class CommunityPost {
  final String id;
  final String author;
  final String authorInitial;
  final String animal;
  final String emoji;
  final String content;
  final String? imageEmoji;
  final int likes;
  final int comments;
  final DateTime postedAt;
  bool liked;

  CommunityPost({
    required this.id,
    required this.author,
    required this.authorInitial,
    required this.animal,
    required this.emoji,
    required this.content,
    this.imageEmoji,
    required this.likes,
    required this.comments,
    required this.postedAt,
    this.liked = false,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<CommunityPost> _posts = [
    CommunityPost(
      id: '1',
      author: 'Lucas M.',
      authorInitial: 'L',
      animal: 'Pogona',
      emoji: '🦎',
      content:
          'Mon pogona adore sa nouvelle lampe UVB ! Température stabilisée à 32°C côté chaud, 26°C côté froid. Il est beaucoup plus actif depuis.',
      imageEmoji: '☀️',
      likes: 24,
      comments: 5,
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CommunityPost(
      id: '2',
      author: 'Marie L.',
      authorInitial: 'M',
      animal: 'Python royal',
      emoji: '🐍',
      content:
          'Question : quelle humidité recommandez-vous pour un python royal en mue ? Mon boîtier indique 68% mais je me demande si c\'est suffisant.',
      likes: 8,
      comments: 12,
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    CommunityPost(
      id: '3',
      author: 'Thomas B.',
      authorInitial: 'T',
      animal: 'Gecko léopard',
      emoji: '🦖',
      content:
          'Partage de mon setup automatisé avec TerrariumApp 🎉 Le scénario "mode nuit" fonctionne parfaitement, la température descend doucement à 22°C à 20h pile.',
      imageEmoji: '🌙',
      likes: 41,
      comments: 9,
      postedAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    CommunityPost(
      id: '4',
      author: 'Sophie R.',
      authorInitial: 'S',
      animal: 'Caméléon voilé',
      emoji: '🦜',
      content:
          'Attention aux propriétaires de caméléons : n\'oubliez pas que ces animaux ont besoin d\'un gradient d\'humidité important. Mon brumisateur tourne 3 fois par jour.',
      likes: 17,
      comments: 3,
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CommunityPost(
      id: '5',
      author: 'Alex D.',
      authorInitial: 'A',
      animal: 'Tortue grecque',
      emoji: '🐢',
      content:
          'Première hibernation de ma tortue grecque supervisée avec des capteurs. Température maintenue entre 4°C et 8°C dans la cave. Tout se passe bien !',
      imageEmoji: '❄️',
      likes: 33,
      comments: 7,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<Map<String, String>> _tips = [
    {
      'emoji': '🌡️',
      'title': 'Gradient thermique',
      'body':
          'Tout reptile a besoin d\'une zone chaude et d\'une zone fraîche pour thermoréguler. Prévois toujours au moins 8°C d\'écart entre les deux extrémités.',
    },
    {
      'emoji': '💧',
      'title': 'Humidité & mue',
      'body':
          'Augmente l\'humidité à 80–90% lors des mues de ton serpent ou gecko. Une mue incomplète peut causer des infections cutanées.',
    },
    {
      'emoji': '☀️',
      'title': 'Cycle lumière',
      'body':
          'Reproduis le cycle jour/nuit naturel de l\'espèce. En général 12h de lumière en été, 10h en hiver. L\'automatisation TerrariumApp simplifie ça.',
    },
    {
      'emoji': '🔌',
      'title': 'Sécurité électrique',
      'body':
          'Utilise toujours des prises étanches près des zones humides. Un thermostat de sécurité évite les surchauffes en cas de panne.',
    },
    {
      'emoji': '🥗',
      'title': 'Supplémentation',
      'body':
          'Saupoudre calcium + vitamine D3 sur les proies 2× par semaine pour les lézards insectivores. La carence est l\'une des causes de maladie les plus fréquentes.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }

  void _toggleLike(String id) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == id);
      post.liked = !post.liked;
    });
  }

  void _showNewPostSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3F2D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nouveau post',
                style: TextStyle(
                    color: Color(0xFFE8F0E8),
                    fontSize: 18,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 5,
              style: const TextStyle(color: Color(0xFFE8F0E8)),
              decoration: const InputDecoration(
                hintText:
                    'Partage ton expérience, pose une question, donne un conseil…',
                hintStyle: TextStyle(color: Color(0xFF2D3F2D)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2D3F2D))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ADE80))),
                filled: true,
                fillColor: Color(0xFF242B24),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                setState(() {
                  _posts.insert(
                    0,
                    CommunityPost(
                      id: DateTime.now().toString(),
                      author: 'Moi',
                      authorInitial: 'M',
                      animal: 'Mon animal',
                      emoji: '🦎',
                      content: ctrl.text.trim(),
                      likes: 0,
                      comments: 0,
                      postedAt: DateTime.now(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: const Color(0xFF1A1F1A),
              ),
              child: const Text('Publier',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _posts
        .where((p) =>
            _searchQuery.isEmpty ||
            p.content
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            p.author
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            p.animal
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Communauté',
                    style: TextStyle(
                        color: Color(0xFFE8F0E8),
                        fontSize: 22,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Échangez avec d\'autres passionnés',
                    style:
                        TextStyle(color: Color(0xFF6B8F6B), fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  // Barre de recherche
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: Color(0xFFE8F0E8), fontSize: 14),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher…',
                      hintStyle:
                          const TextStyle(color: Color(0xFF2D3F2D)),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF6B8F6B), size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Color(0xFF6B8F6B), size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF2D3F2D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF4ADE80)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF242B24),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4ADE80),
              labelColor: const Color(0xFF4ADE80),
              unselectedLabelColor: const Color(0xFF6B8F6B),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Publications'),
                Tab(text: 'Conseils'),
              ],
            ),

            // ── Contenu ───────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Onglet Publications ──────────────────────────
                  filteredPosts.isEmpty
                      ? const Center(
                          child: Text('Aucun résultat',
                              style: TextStyle(color: Color(0xFF6B8F6B))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredPosts.length,
                          itemBuilder: (ctx, i) => _PostCard(
                            post: filteredPosts[i],
                            timeAgo: _timeAgo(filteredPosts[i].postedAt),
                            onLike: () => _toggleLike(filteredPosts[i].id),
                          ),
                        ),

                  // ── Onglet Conseils ──────────────────────────────
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tips.length,
                    itemBuilder: (ctx, i) => _TipCard(tip: _tips[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPostSheet,
        backgroundColor: const Color(0xFF4ADE80),
        foregroundColor: const Color(0xFF1A1F1A),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String timeAgo;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.timeAgo,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF242B24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header auteur
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3F2D),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    post.authorInitial,
                    style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author,
                        style: const TextStyle(
                            color: Color(0xFFE8F0E8),
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    Row(
                      children: [
                        Text(post.emoji,
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(post.animal,
                            style: const TextStyle(
                                color: Color(0xFF6B8F6B), fontSize: 11)),
                        const Text(' · ',
                            style: TextStyle(
                                color: Color(0xFF6B8F6B), fontSize: 11)),
                        Text(timeAgo,
                            style: const TextStyle(
                                color: Color(0xFF6B8F6B), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Contenu
          Text(
            post.content,
            style: const TextStyle(
                color: Color(0xFFE8F0E8), fontSize: 13, height: 1.5),
          ),

          // Image emoji déco
          if (post.imageEmoji != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                post.imageEmoji!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post.liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.liked
                          ? const Color(0xFFFB7185)
                          : const Color(0xFF6B8F6B),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes + (post.liked ? 1 : 0)}',
                      style: TextStyle(
                          color: post.liked
                              ? const Color(0xFFFB7185)
                              : const Color(0xFF6B8F6B),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF6B8F6B), size: 16),
                  const SizedBox(width: 4),
                  Text('${post.comments}',
                      style: const TextStyle(
                          color: Color(0xFF6B8F6B), fontSize: 13)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.share_outlined,
                  color: Color(0xFF6B8F6B), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatefulWidget {
  final Map<String, String> tip;
  const _TipCard({required this.tip});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF242B24),
          borderRadius: BorderRadius.circular(14),
          border: _expanded
              ? Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.tip['emoji']!,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.tip['title']!,
                    style: const TextStyle(
                        color: Color(0xFFE8F0E8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6B8F6B),
                  size: 18,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.tip['body']!,
                style: const TextStyle(
                    color: Color(0xFF6B8F6B), fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
