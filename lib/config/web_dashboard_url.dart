/// Donor neighbourhood dashboard (Vite web app). Set at build time:
/// `--dart-define=WEB_DASHBOARD_URL=https://<static-site>.onrender.com`
class WebDashboardUrl {
  WebDashboardUrl._();

  static const String value = String.fromEnvironment(
    'WEB_DASHBOARD_URL',
    defaultValue: '',
  );

  static bool get isConfigured => value.trim().isNotEmpty;
}
