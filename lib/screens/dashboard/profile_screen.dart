import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../tools/app_localizations.dart';
import '../../tools/app_routes.dart';
import '../../tools/gw_design.dart';

/// Fase C profile screen: user hub with wallet management, settings
/// shortcuts, exchange API keys, and about links.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.instance.translate('profile_link_failed'),
          ),
        ),
      );
    }
  }

  Widget _menuRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GwDesign.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GwDesign.spacingCard,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: GwDesign.cardBackground,
          borderRadius: BorderRadius.circular(GwDesign.radiusCard),
          border: Border.all(color: GwDesign.cardBorder.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: GwDesign.mintAccent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: GwDesign.menuLabel),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: GwDesign.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.instance.translate;
    return Scaffold(
      backgroundColor: GwDesign.background,
      appBar: AppBar(
        backgroundColor: GwDesign.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('dashboard_nav_profile'), style: GwDesign.appBarTitle),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
              : '';
          return ListView(
            padding: const EdgeInsets.all(GwDesign.spacingScreen),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(GwDesign.spacingCard + 8),
                decoration: BoxDecoration(
                  gradient: GwDesign.heroCardGradient,
                  borderRadius:
                      BorderRadius.circular(GwDesign.radiusCard),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GwDesign.mintAccent,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: GwDesign.background,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GreenWallet', style: GwDesign.heroLabel),
                          if (version.isNotEmpty)
                            Text(
                              'v$version',
                              style: GwDesign.mutedSmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Wallet section
              Text(t('profile_section_wallet'), style: GwDesign.sectionLabel),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: t('profile_my_wallets'),
                onTap: () =>
                    Navigator.pushNamed(context, Routes.walletList),
              ),
              const SizedBox(height: 20),
              // Settings section
              Text(t('profile_section_settings'), style: GwDesign.sectionLabel),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.palette_outlined,
                label: t('profile_appearance'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.appSettingsAppTheme,),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.language_rounded,
                label: t('profile_language'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.appSettingsLanguage,),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.security_rounded,
                label: t('profile_security'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.appSettingsAuthentication,),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.notifications_outlined,
                label: t('profile_notifications'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.appSettingsNotifications,),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.dns_outlined,
                label: t('profile_network'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.serverSettingsHome,),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.key_rounded,
                label: t('profile_exchange_api'),
                onTap: () => Navigator.pushNamed(
                    context, Routes.exchangeApi,),
              ),
              const SizedBox(height: 20),
              // About section
              Text(t('profile_section_about'), style: GwDesign.sectionLabel),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.public_rounded,
                label: 'nusacoin.org',
                onTap: () => _openUrl(context, 'https://nusacoin.org'),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.link_rounded,
                label: 'nusachain.org',
                onTap: () => _openUrl(context, 'https://nusachain.org'),
              ),
              const SizedBox(height: 8),
              _menuRow(
                context,
                icon: Icons.code_rounded,
                label: 'GitHub',
                onTap: () => _openUrl(
                    context, 'https://github.com/TaobotX11/greenwallet',),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
