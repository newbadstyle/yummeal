// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yummeal/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  Map<String, dynamic>? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Załaduj dane lokalne z AuthService
      final data = await _authService.getUserData();

      setState(() {
        userProfile = data;
        isLoading = false;
      });

      print('Profile loaded: $data');
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getGenderText(int? genderValue) {
    switch (genderValue) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 16,
                            color: Colors.black,
                          ),
                          Text(
                            'Back',
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 60), // Balance the back button
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile header with avatar and username
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${userProfile?['firstName'] ?? userProfile?['FirstName'] ?? 'User'} ${userProfile?['lastName'] ?? userProfile?['LastName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                if (userProfile?['email'] != null)
                                  Text(
                                    userProfile!['email'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Premium Subscription
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Premium Subscription',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Unlimited nutrition tracking',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Menu items
                    _buildMenuItem('Goals', ''),
                    const SizedBox(height: 1),
                    _buildMenuItem('Analytics', ''),
                    const SizedBox(height: 1),
                    _buildMenuItem('Features', ''),

                    const SizedBox(height: 32),

                    // Personal Information
                    _buildInfoItem(
                      'Gender',
                      _getGenderText(userProfile?['Gender']),
                    ),
                    const SizedBox(height: 1),
                    _buildInfoItem('Age', '${userProfile?['Age'] ?? 25} years'),
                    const SizedBox(height: 1),
                    _buildInfoItem(
                      'Height',
                      '${userProfile?['Height'] ?? 170}cm',
                    ),
                    const SizedBox(height: 1),
                    _buildInfoItem(
                      'Current weight',
                      '${userProfile?['CurrentWeight'] ?? 45}kg',
                    ),
                    const SizedBox(height: 1),
                    _buildInfoItem(
                      'Target weight',
                      '${userProfile?['TargetWeight'] ?? 60}kg',
                    ),
                    const SizedBox(height: 1),
                    _buildInfoItem(
                      'Activity Level',
                      _getActivityLevelText(userProfile?['ActivityLevel']),
                    ),

                    const SizedBox(height: 32),

                    // Help section
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Help',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem('Contact Us', ''),
                    const SizedBox(height: 1),
                    _buildMenuItem('Privacy Policy', ''),

                    const SizedBox(height: 40),

                    // Logout button
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityLevelText(int? level) {
    switch (level) {
      case 1:
        return 'Sedentary';
      case 2:
        return 'Lightly Active';
      case 3:
        return 'Moderately Active';
      case 4:
        return 'Very Active';
      case 5:
        return 'Extra Active';
      default:
        return 'Sedentary';
    }
  }

  Widget _buildMenuItem(String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        // Handle menu item tap
        if (title == 'Goals') {
          _showGoalsDialog();
        } else if (title == 'Analytics') {
          _showAnalyticsDialog();
        } else if (title == 'Features') {
          _showFeaturesDialog();
        } else if (title == 'Contact Us') {
          _showContactDialog();
        } else if (title == 'Privacy Policy') {
          _showPrivacyDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return GestureDetector(
      onTap: () {
        _showEditDialog(label, value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    String selectedGender = currentValue;
    int selectedActivityLevel = userProfile?['ActivityLevel'] ?? 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit $field'),
              content:
                  field == 'Gender'
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'Male',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value!;
                                controller.text = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'Female',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value!;
                                controller.text = value;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Other'),
                            value: 'Other',
                            groupValue: selectedGender,
                            onChanged: (value) {
                              setState(() {
                                selectedGender = value!;
                                controller.text = value;
                              });
                            },
                          ),
                        ],
                      )
                      : field == 'Activity Level'
                      ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<int>(
                            title: const Text('Sedentary'),
                            value: 1,
                            groupValue: selectedActivityLevel,
                            onChanged: (value) {
                              setState(() {
                                selectedActivityLevel = value!;
                                controller.text = _getActivityLevelText(value);
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Lightly Active'),
                            value: 2,
                            groupValue: selectedActivityLevel,
                            onChanged: (value) {
                              setState(() {
                                selectedActivityLevel = value!;
                                controller.text = _getActivityLevelText(value);
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Moderately Active'),
                            value: 3,
                            groupValue: selectedActivityLevel,
                            onChanged: (value) {
                              setState(() {
                                selectedActivityLevel = value!;
                                controller.text = _getActivityLevelText(value);
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Very Active'),
                            value: 4,
                            groupValue: selectedActivityLevel,
                            onChanged: (value) {
                              setState(() {
                                selectedActivityLevel = value!;
                                controller.text = _getActivityLevelText(value);
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Extra Active'),
                            value: 5,
                            groupValue: selectedActivityLevel,
                            onChanged: (value) {
                              setState(() {
                                selectedActivityLevel = value!;
                                controller.text = _getActivityLevelText(value);
                              });
                            },
                          ),
                        ],
                      )
                      : TextField(
                        controller: controller,
                        keyboardType:
                            field.contains('weight') ||
                                    field.contains('Height') ||
                                    field.contains('Age')
                                ? TextInputType.number
                                : TextInputType.text,
                        inputFormatters:
                            field.contains('weight') ||
                                    field.contains('Height') ||
                                    field.contains('Age')
                                ? [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.]'),
                                  ),
                                ]
                                : null,
                        decoration: InputDecoration(
                          hintText: 'Enter $field',
                          border: const OutlineInputBorder(),
                        ),
                      ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (field == 'Activity Level') {
                      await _updateProfile(
                        field,
                        selectedActivityLevel.toString(),
                      );
                    } else {
                      await _updateProfile(field, controller.text);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateProfile(String field, String value) async {
    try {
      final currentUserData = await _authService.getUserData();
      if (currentUserData == null) return;

      String dbField;
      dynamic dbValue = value;

      switch (field) {
        case 'Gender':
          dbField = 'Gender';
          if (value == 'Male') {
            dbValue = 1;
          } else if (value == 'Female') {
            dbValue = 2;
          } else {
            dbValue = 0; // Other
          }
          break;
        case 'Age':
          dbField = 'Age';
          dbValue = int.tryParse(value.replaceAll(' years', '')) ?? 0;
          break;
        case 'Height':
          dbField = 'Height';
          dbValue = int.tryParse(value.replaceAll('cm', '')) ?? 0;
          break;
        case 'Current weight':
          dbField = 'CurrentWeight';
          dbValue = int.tryParse(value.replaceAll('kg', '')) ?? 0;
          break;
        case 'Target weight':
          dbField = 'TargetWeight';
          dbValue = int.tryParse(value.replaceAll('kg', '')) ?? 0;
          break;
        case 'Activity Level':
          dbField = 'ActivityLevel';
          dbValue = int.tryParse(value) ?? 1;
          break;
        default:
          return;
      }

      // Update local data
      currentUserData[dbField] = dbValue;
      await _authService.saveAuthDataPublic(currentUserData);

      // Reload profile
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  // Dialog functions
  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Goals'),
            content: const Text('Set your fitness and nutrition goals here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Analytics'),
            content: const Text('View your progress and statistics here.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showFeaturesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Features'),
            content: const Text(
              'Explore available features and premium options.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Us'),
            content: const Text(
              'Get in touch with our support team at support@yummeal.com',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: const Text(
              'Read our privacy policy to understand how we protect your data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
