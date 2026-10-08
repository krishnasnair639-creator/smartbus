import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'destination_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'sos_screen.dart';
import '../services/theme_service.dart';

const Color kProfilePurple = Color(0xFF6C4DF6);
Color get kProfileBackground => AppThemeService.instance.pageBackground;
Color get kCardWhite => AppThemeService.instance.surface;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? fullName;
  String? email;
  String? phoneNumber;
  int? userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        if (user != null) {
          fullName = (user['username'] ?? user['name'] ?? user['full_name'])
              ?.toString()
              .trim();
          email = user['email']?.toString();
          phoneNumber = user['phone']?.toString();
          userId = user['id'] is int
              ? user['id'] as int
              : int.tryParse(user['id']?.toString() ?? '1') ?? 1;
        } else {
          fullName = null;
          email = null;
          phoneNumber = null;
          userId = null;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kProfileBackground,
      appBar: AppBar(
        backgroundColor: kProfileBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppThemeService.instance.primaryText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppThemeService.instance.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kProfilePurple),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kCardWhite,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile Avatar with Initials
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: kProfilePurple.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kProfilePurple.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(fullName),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: kProfilePurple,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName?.isNotEmpty == true
                                ? fullName!
                                : 'Username unavailable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppThemeService.instance.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email?.isNotEmpty == true
                                ? email!
                                : 'No email linked',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppThemeService.instance.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                          if (phoneNumber?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              phoneNumber!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppThemeService.instance.mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _editProfile,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kProfilePurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ==================================================
                    // PERSONAL INFORMATION
                    // ==================================================
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 8),
                    _buildInfoTile(
                      icon: Icons.person_outline,
                      title: 'Full Name',
                      value: fullName,
                    ),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: email,
                    ),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      value: phoneNumber,
                    ),
                    const SizedBox(height: 22),

                    _buildSectionTitle('Appearance'),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppThemeService.instance.themeMode,
                      builder: (context, themeMode, _) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kCardWhite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('Default'),
                              icon: Icon(Icons.brightness_auto_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                              icon: Icon(Icons.light_mode_outlined),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                              icon: Icon(Icons.dark_mode_outlined),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (selection) {
                            AppThemeService.instance.setThemeMode(
                              selection.first,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ==================================================
                    // ACCOUNT SHORTCUTS & ACTIONS
                    // ==================================================
                    _buildSectionTitle('Account & Quick Links'),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your login credentials',
                      onTap: _changePassword,
                    ),
                    _buildActionTile(
                      icon: Icons.emergency_outlined,
                      title: 'Emergency Contacts & SOS',
                      subtitle: 'Manage guardians and quick dial contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SosScreen(userId: userId ?? 1),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.history,
                      title: 'Journey History',
                      subtitle: 'View completed trips and routes',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildActionTile(
                      icon: Icons.bookmark_outline,
                      title: 'Saved Destinations',
                      subtitle: 'Frequent bus stops and drop locations',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DestinationScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),

                    // ==================================================
                    // ABOUT & LOGOUT
                    // ==================================================
                    _buildSectionTitle('About'),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      icon: Icons.info_outline,
                      title: 'About SmartBus Guardian',
                      subtitle: 'Version 1.0.0 • Smart Travel Safety',
                      onTap: _showAbout,
                    ),
                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'SmartBus Guardian',
                      style: TextStyle(
                        color: AppThemeService.instance.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your smart & safe journey companion',
                      style: TextStyle(
                        color: AppThemeService.instance.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppThemeService.instance.primaryText,
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION TILE
  // ============================================================
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String? value,
  }) {
    final bool hasValue = value != null && value.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kProfilePurple.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kProfilePurple, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppThemeService.instance.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          hasValue ? value : 'Not added',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: hasValue
                ? AppThemeService.instance.primaryText
                : AppThemeService.instance.mutedText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION TILE
  // ============================================================
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kProfilePurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kProfilePurple, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppThemeService.instance.primaryText,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppThemeService.instance.mutedText,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 15,
            color: AppThemeService.instance.mutedText,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: fullName ?? '');
    final emailController = TextEditingController(text: email ?? '');
    final phoneController = TextEditingController(text: phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit, color: kProfilePurple),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter your name'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null ||
                            !RegExp(
                              r'^[\w.-]+@[\w.-]+\.[A-Za-z]{2,}$',
                            ).hasMatch(value.trim())
                        ? 'Enter a valid email address'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (val) => (val == null || val.trim().length < 10)
                        ? 'Enter a valid phone number'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kProfilePurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final updatedName = nameController.text.trim();
      final updatedEmail = emailController.text.trim();
      final updatedPhone = phoneController.text.trim();

      await AuthService.instance.updateProfile(
        name: updatedName,
        email: updatedEmail,
        phone: updatedPhone,
      );

      if (mounted) {
        setState(() {
          fullName = updatedName;
          email = updatedEmail;
          phoneNumber = updatedPhone;
        });
        _showMessage('Profile updated successfully.');
      }
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================
  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: kProfilePurple),
              SizedBox(width: 8),
              Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Enter current password'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    validator: (val) => (val == null || val.length < 6)
                        ? 'Must be at least 6 characters'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_open),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    validator: (val) {
                      if (val != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: kProfileBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final error = await AuthService.instance.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (error != null) {
                    _showMessage(error, isError: true);
                  } else {
                    _showMessage('Password changed successfully.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kProfilePurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmController.dispose();
  }

  // ============================================================
  // ABOUT
  // ============================================================
  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.directions_bus, color: kProfilePurple),
              SizedBox(width: 8),
              Text('SmartBus Guardian'),
            ],
          ),
          content: const Text(
            'SmartBus Guardian is an intelligent passenger travel safety '
            'system designed to keep bus riders safe and informed.\n\n'
            'Features include:\n'
            '• Live GPS route and destination tracking\n'
            '• Smart destination voice & vibration wake-up alerts\n'
            '• Sleep Mode protection for night travel\n'
            '• Instant SOS panic alert, loud audio siren, & emergency contact SMS',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kProfilePurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to log out of SmartBus Guardian?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    await AuthService.instance.logout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // MESSAGE HELPER
  // ============================================================
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
      ),
    );
  }
}
