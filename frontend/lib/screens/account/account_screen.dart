import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:urbancare_frontend/models/user.dart';
import 'package:urbancare_frontend/repositories/auth_repository.dart';
import 'package:urbancare_frontend/widgets/primary_button.dart';
import 'package:urbancare_frontend/widgets/text_input.dart';
import 'package:urbancare_frontend/theme/app_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.authRepository,
    required this.onSignOut,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.notificationsEnabled,
    required this.onNotificationEnabledChanged,
  });

  final AuthRepository authRepository;
  final VoidCallback onSignOut;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationEnabledChanged;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      // Try fetching fresh from API first
      final user = await widget.authRepository.getProfile();
      if (!mounted) return;
      _populate(user);
      setState(() => _user = user);
    } catch (_) {
      // Fall back to locally cached session
      final cached = await widget.authRepository.getSavedUser();
      if (!mounted) return;
      if (cached != null) {
        _populate(cached);
        setState(() => _user = cached);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populate(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = await widget.authRepository.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _changePassword && _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );
      if (!mounted) return;
      setState(() {
        _user = updated;
        _changePassword = false;
      });
      _passwordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await widget.authRepository.logout();
    widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Account',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your profile and settings.',
                      style: TextStyle(color: context.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF16A34A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (_user?.name.isNotEmpty == true)
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.syne(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _user?.name ?? '',
                        style: GoogleFonts.syne(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Profile section
                    _sectionLabel('PROFILE DETAILS'),
                    const SizedBox(height: 12),
                    TextInput(
                      controller: _nameController,
                      hint: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextInput(
                      controller: _emailController,
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextInput(
                      controller: _phoneController,
                      hint: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Change password toggle
                    _sectionLabel('SECURITY'),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => setState(() => _changePassword = !_changePassword),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.fill04,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 20,
                                color: context.onSurfaceVariant),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Change password',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(
                              _changePassword
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: context.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_changePassword) ...[
                      const SizedBox(height: 12),
                      TextInput(
                        controller: _passwordController,
                        hint: 'New password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v == null || v.length < 8) {
                            return 'Minimum 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextInput(
                        controller: _confirmPasswordController,
                        hint: 'Confirm new password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        validator: (v) {
                          if (!_changePassword) return null;
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: 'Save Changes',
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 28),

                    // Settings section
                    _sectionLabel('PREFERENCES'),
                    const SizedBox(height: 10),
                    _settingsTile(
                      icon: widget.currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      title: 'Theme',
                      subtitle: widget.currentThemeMode == ThemeMode.dark
                          ? 'Dark mode'
                          : 'Light mode',
                      trailing: PopupMenuButton<ThemeMode>(
                        tooltip: 'Change theme',
                        initialValue: widget.currentThemeMode,
                        onSelected: widget.onThemeModeChanged,
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                          PopupMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.fill08,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Change',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.onSurfaceVariant)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down,
                                  size: 16, color: context.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _settingsTile(
                      icon: widget.notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      title: 'Notifications',
                      subtitle: widget.notificationsEnabled ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: widget.notificationsEnabled,
                        onChanged: widget.onNotificationEnabledChanged,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign out
                    _sectionLabel('ACCOUNT'),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Sign Out',
                      isSecondary: true,
                      onPressed: _signOut,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.fill04,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: context.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
