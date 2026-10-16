import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:greenwallet/widgets/service_container.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../tools/app_localizations.dart';
import '../tools/app_routes.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _initial = true;
  late PackageInfo _packageInfo;

  @override
  void didChangeDependencies() async {
    if (_initial) {
      _packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _initial = false;
      });
    }
    super.didChangeDependencies();
  }

  void _launchURL(String url) async {
    await canLaunchUrlString(url)
        ? await launchUrlString(
            url,
          )
        : throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    if (_initial) return const SizedBox();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.instance.translate('about'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                child: AppContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(_packageInfo.appName),
                      Text(
                        'Version ${_packageInfo.version} Build ${_packageInfo.buildNumber}',
                      ),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_developers',
                          {'year': DateFormat.y().format(DateTime.now())},
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchURL(
                          'https://github.com/Melkisedek03/GreenWallet/blob/main/LICENSE',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_license',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: () => showLicensePage(context: context),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_show_license',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(Routes.changeLog),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'changelog_appbar',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_free',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchURL(
                          'https://github.com/Melkisedek03/GreenWallet',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_view_source',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_data_protection',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchURL(
                          'https://github.com/Melkisedek03/GreenWallet/blob/main/data_protection.md',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_data_declaration',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_translate',
                        ),
                      ),
                      TextButton(
                        onPressed: () async => _launchURL(
                          'https://github.com/Melkisedek03/GreenWallet',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_go_github',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_help_or_feedback',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchURL(
                          'https://github.com/Melkisedek03/GreenWallet/issues',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_open_issues',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.instance.translate(
                          'about_illustrations',
                        ),
                      ),
                      TextButton(
                        onPressed: () async => _launchURL(
                          'https://designs.ai',
                        ),
                        child: Text(
                          AppLocalizations.instance.translate(
                            'about_illustrations_button',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
