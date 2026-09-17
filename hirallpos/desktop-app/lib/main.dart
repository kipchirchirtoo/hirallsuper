import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/activation/screens/activation_screen.dart';
import 'features/shell/screens/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final isActivated = prefs.getBool(AppConstants.keyIsActivated) ?? false;
  final orgName = isActivated ? prefs.getString(AppConstants.keyOrgName) : null;
  final branchName = prefs.getString(AppConstants.keyBranchName);
  final businessType = prefs.getString(AppConstants.keyBusinessType);
  final enabledModules = prefs.getStringList(AppConstants.keyEnabledModules);

  runApp(
    ProviderScope(
      child: GiftmartPosApp(
        organizationName: orgName,
        branchName: branchName,
        businessType: businessType,
        enabledModules: enabledModules,
      ),
    ),
  );
}

class GiftmartPosApp extends ConsumerWidget {
  final String? organizationName;
  final String? branchName;
  final String? businessType;
  final List<String>? enabledModules;

  const GiftmartPosApp({
    super.key,
    this.organizationName,
    this.branchName,
    this.businessType,
    this.enabledModules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: organizationName != null && branchName != null
          ? MainShellScreen(
              organizationName: organizationName!,
              branchName: branchName!,
              businessType: businessType ?? 'supermarket',
              enabledModules: enabledModules ??
                  const [
                    'cashier',
                    'storekeeping',
                    'accounting',
                    'hr_management',
                    'pos_outlets',
                  ],
            )
          : const ActivationScreen(),
    );
  }
}

/// Backward compatibility alias for tests
typedef HirallPosApp = GiftmartPosApp;
