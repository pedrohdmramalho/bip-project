import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:starteu/auth/services/auth_service.dart';

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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

            // --- PROFILE PICTURE SECTION ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.deepPurple, width: 3),
                      color: Colors.grey[200],
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

            // --- USER INFO ---
            _buildInfoTile(Icons.person, "Name", user?.displayName ?? "User"),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.email, "Email", user?.email ?? "No Email"),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.perm_identity, "User ID", user?.uid ?? ""),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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
