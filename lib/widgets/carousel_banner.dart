import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';

class _BannerData {
  final String title;
  final String subtitle;
  final String image;
  final Color color;

  const _BannerData(this.title, this.subtitle, this.image, this.color);
}

const List<_BannerData> _banners = [
  _BannerData(
    'Peralatan Lab Lengkap',
    'Laptop, jaringan, dan elektronik siap dipakai',
    'https://picsum.photos/seed/lab-banner-1/900/400',
    AppColors.primary,
  ),
  _BannerData(
    'Pinjam dengan Mudah',
    'Pilih alat, tekan Pinjam, selesai',
    'https://picsum.photos/seed/lab-banner-2/900/400',
    AppColors.roseDark,
  ),
  _BannerData(
    'Data Real-time',
    'Status alat selalu terbarui otomatis',
    'https://picsum.photos/seed/lab-banner-3/900/400',
    AppColors.accent,
  ),
];

/// Carousel Slider: bisa digeser dan berpindah otomatis tiap 4 detik.
class CarouselBanner extends StatefulWidget {
  const CarouselBanner({super.key});

  @override
  State<CarouselBanner> createState() => _CarouselBannerState();
}

class _CarouselBannerState extends State<CarouselBanner> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _BannerItem(data: _banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFF0D8D8),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerItem extends StatelessWidget {
  final _BannerData data;

  const _BannerItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  Container(color: data.color),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    data.color.withValues(alpha: 0.92),
                    data.color.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.subtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
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
