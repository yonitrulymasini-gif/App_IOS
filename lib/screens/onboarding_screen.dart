import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.eco_outlined,
      iconColor: T.green,
      bgColor: Color(0xFF162018),
      title: 'Bienvenue dans Terra',
      subtitle: 'Ton terrarium connecté tient désormais dans ta poche. Une jungle vivante à portée de doigt.',
    ),
    _Slide(
      icon: Icons.monitor_heart_outlined,
      iconColor: T.gold,
      bgColor: Color(0xFF1A1A10),
      title: 'Surveille en temps réel',
      subtitle: 'Température, humidité, état des prises — tout est synchronisé via tes capteurs ESP32.',
    ),
    _Slide(
      icon: Icons.auto_awesome_outlined,
      iconColor: T.green,
      bgColor: Color(0xFF162018),
      title: 'Automatise sans coder',
      subtitle: 'Crée des scénarios : lampe le matin, brumisation l\'après-midi, chauffage la nuit.',
    ),
    _Slide(
      icon: Icons.people_outline_rounded,
      iconColor: T.gold,
      bgColor: Color(0xFF1A1A10),
      title: 'Partage ta jungle',
      subtitle: 'Rejoins une communauté de terrariophiles passionnés. Échange photos, conseils et configs.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terra.', style: T.serif(22).copyWith(letterSpacing: -0.5)),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const AuthScreen())),
                    child: Text('Passer', style: T.t15.copyWith(color: T.textSecondary)),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 6,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == _page ? T.textPrimary : T.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  // Button
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        color: T.greenBtn,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          _page < _slides.length - 1 ? 'Continuer' : 'Commencer',
                          style: T.t17.copyWith(color: const Color(0xFF0A1A0F)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  const _Slide({required this.icon, required this.iconColor, required this.bgColor,
    required this.title, required this.subtitle});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: slide.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, color: slide.iconColor, size: 52),
          ),
          const SizedBox(height: 48),
          Text(slide.title, style: T.serif(34), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(slide.subtitle,
              style: T.t16.copyWith(color: T.textSecondary, height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
