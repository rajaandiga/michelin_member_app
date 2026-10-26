import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';

class _Ring extends StatelessWidget {
  final double size;
  final double alpha;
  const _Ring(this.size, this.alpha);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha),
          width: 14,
        ),
      ),
    );
  }
}

class MemberCardFront extends StatelessWidget {
  final Profile profile;
  const MemberCardFront({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(right: -70, bottom: -80, child: _Ring(230, 0.05)),
            const Positioned(right: -20, bottom: -30, child: _Ring(130, 0.06)),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: AppColors.yellow),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MICHELIN MyXpert',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tier(profile.tier),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              profile.tier,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    profile.memberNo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member sejak ${tanggal(profile.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'POIN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${profile.points}',
                            style: const TextStyle(
                              color: AppColors.yellow,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class MemberCardBack extends StatelessWidget {
  final Profile profile;
  const MemberCardBack({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            Container(height: 40, color: AppColors.navy),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ketentuan kartu',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Kartu ini milik pribadi dan tidak boleh dipindahtangankan.\n'
                        '2. Poin didapat dari setiap pembelian ban dan layanan.\n'
                        '3. Tunjukkan kartu saat bertransaksi di gerai.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    profile.memberNo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    profile.tier,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.tier(profile.tier),
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