import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:starteu/auth/services/auth_service.dart';
import '../config/theme_mode_manager.dart';

class ProfilePage extends StatefulWidget {
  final AuthService authService;

  const ProfilePage({super.key, required this.authService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  User? get _firebaseUser => FirebaseAuth.instance.currentUser;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isUploading = true);
      final File file = File(image.path);
      final String userId = _firebaseUser?.uid ?? 'unknown';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics')
          .child('$userId.jpg');

      await ref.putFile(file);
      final String downloadUrl = await ref.getDownloadURL();

      await _firebaseUser?.updatePhotoURL(downloadUrl);
      await _firebaseUser?.reload();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } on FirebaseException catch (e) {
      print("Firebase Storage Error: [${e.code}] ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: ${e.message}')));
      }
    } catch (e) {
      print("General Error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeProfilePicture() async {
    try {
      setState(() => _isUploading = true);

      // Remove from Auth
      await _firebaseUser?.updatePhotoURL(null);
      await _firebaseUser?.reload();

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed.')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final photoUrl = _firebaseUser?.photoURL;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => widget.authService.signOut(),
            tooltip: "Logout",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 3),
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      image: photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),

                  // Edit Button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (photoUrl != null)
              TextButton(
                onPressed: _removeProfilePicture,
                child: const Text(
                  "Remove Photo",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 30),

            _buildInfoTile(Icons.person, "Name", user?.displayName ?? "User"),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.email, "Email", user?.email ?? "No Email"),
            
            const SizedBox(height: 30),
            
            // Theme Mode Selector
            Text(
              "Appearance",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Consumer<ThemeModeManager>(
              builder: (context, themeModeManager, _) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      _buildThemeTile(
                        context,
                        Icons.light_mode,
                        'Light Mode',
                        ThemeMode.light,
                        themeModeManager,
                      ),
                      Divider(height: 1, color: Colors.grey[300]),
                      _buildThemeTile(
                        context,
                        Icons.dark_mode,
                        'Dark Mode',
                        ThemeMode.dark,
                        themeModeManager,
                      ),
                      Divider(height: 1, color: Colors.grey[300]),
                      _buildThemeTile(
                        context,
                        Icons.brightness_auto,
                        'System',
                        ThemeMode.system,
                        themeModeManager,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    IconData icon,
    String label,
    ThemeMode mode,
    ThemeModeManager themeModeManager,
  ) {
    final isSelected = themeModeManager.themeMode == mode;
    
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.deepPurple)
          : null,
      onTap: () {
        themeModeManager.setThemeMode(mode);
      },
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withOpacity(0.1),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
