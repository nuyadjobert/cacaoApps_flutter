import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/profile_controller.dart';
import '../../../core/widgets/toast.dart';
import '../../../theme/app_theme.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditing = false;
  late final UserProfileController controller;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;
  bool _isSaving = false;

  final List<String> barangayOptions = const [
    'Dacudao',
    'Datu Balong',
    'Igangon',
    'Kipalili',
    'Libuton',
    'Linao',
    'Mamangan',
    'Monte Dujali',
    'Pinamuno',
    'Sabangan',
    'San Miguel',
    'Santo Niño',
    'Poblacion',
  ];

  String? _selectedBarangay;

  @override
  void initState() {
    super.initState();
    controller = UserProfileController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _loadOriginalData();
      }
    });
  }

  Future<void> _loadUser() async {
    await controller.loadUser();
    _loadOriginalData();
  }

  void _loadOriginalData() {
    final user = controller.user;
    if (user != null && mounted) {
      _nameController.text = user.name ?? "";
      _emailController.text = user.email;
      _contactController.text = user.contactNumber;

      if (barangayOptions.contains(user.address)) {
        _selectedBarangay = user.address;
      } else {
        _selectedBarangay = null;
      }
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = controller.user;
    if (currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    TopToast.show(context, "Saving changes...");

    try {
      final result = await controller.updateProfile(
        name: _nameController.text.trim() != (currentUser.name ?? "")
            ? _nameController.text.trim()
            : null,
        address: _selectedBarangay != currentUser.address
            ? _selectedBarangay
            : null,
        contactNumber:
            _contactController.text.trim() != (currentUser.contactNumber)
                ? _contactController.text.trim()
                : null,
      );

      if (!mounted) return;

      // Show appropriate message based on result
      switch (result) {
        case ProfileUpdateResult.successOnline:
          TopToast.show(context, "✅ Profile updated successfully!");
          break;
        case ProfileUpdateResult.savedOffline:
          TopToast.show(
            context,
            "💾 Changes saved offline. They will sync automatically when you're connected.",
          );
          break;
        case ProfileUpdateResult.error:
          TopToast.show(
            context,
            "❌ Failed to update profile. Please try again.",
          );
          break;
      }

      setState(() {
        _isEditing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? AppColors.nightBg : AppColors.creamBg;
    final Color appBarBg = bg;
    final Color cardBg = isDark ? AppColors.nightCard : Colors.white;

    final Color textPrimary = isDark ? Colors.white : AppColors.forestDark;
    final Color textSecondary = isDark
        ? const Color(0xFFA5C9B7) 
        : const Color(0xFF3D6350); 
    final Color accentColor =
        isDark ? AppColors.forestLight : AppColors.forestMid;

    final Color inputFill = isDark
        ? AppColors.nightBg.withAlpha(153)
        : accentColor.withAlpha(25);
    final Color lockedFill = isDark
        ? AppColors.nightBg.withAlpha(230)
        : accentColor.withAlpha(51);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textPrimary),
          title: Text(
            "My Profile",
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _toggleEditMode,
                icon: Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_outlined,
                  size: 18,
                  color: _isEditing ? Colors.redAccent : accentColor,
                ),
                label: Text(
                  _isEditing ? "Cancel" : "Edit",
                  style: TextStyle(
                    color: _isEditing ? Colors.redAccent : accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withAlpha(77),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(30),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: accentColor.withAlpha(30),
                      child: Icon(
                        Icons.person_rounded,
                        color: accentColor,
                        size: 52,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Clean Card Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accentColor.withAlpha(30),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "Full Name",
                      icon: Icons.badge_outlined,
                      isEditable: _isEditing,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                      inputFill: inputFill,
                      lockedFill: lockedFill,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: "Email Address",
                      icon: Icons.email_outlined,
                      isEditable: false,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                      inputFill: inputFill,
                      lockedFill: lockedFill,
                      isLocked: true,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _contactController,
                      label: "Contact Number",
                      icon: Icons.phone_outlined,
                      isEditable: _isEditing,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                      inputFill: inputFill,
                      lockedFill: lockedFill,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildBarangayDropdown(
                      isDark: isDark,
                      isEditable: _isEditing,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                      inputFill: inputFill,
                      cardBg: cardBg,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              AnimatedOpacity(
                opacity: _isEditing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: _isEditing
                    ? SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _isSaving
                                ? const Row(
                                    key: ValueKey("saving"),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Saving...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "Save Changes",
                                    key: ValueKey("idle"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditable,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required Color inputFill,
    required Color lockedFill,
    bool isLocked = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final textColor = isEditable ? textPrimary : textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: true,
          readOnly: !isEditable,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isEditable ? accentColor : textSecondary,
              size: 20,
            ),
            suffixIcon: isLocked
                ? Icon(
                    Icons.lock_rounded,
                    color: accentColor.withAlpha(128),
                    size: 18,
                  )
                : null,
            filled: true,
            fillColor: isLocked
                ? lockedFill
                : (isEditable ? Colors.transparent : inputFill),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: accentColor.withAlpha(30),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isEditable
                    ? accentColor.withAlpha(102)
                    : accentColor.withAlpha(30),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarangayDropdown({
    required bool isDark,
    required bool isEditable,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required Color inputFill,
    required Color cardBg,
  }) {
    final textColor = isEditable ? textPrimary : textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Address (Barangay)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: barangayOptions.contains(_selectedBarangay)
              ? _selectedBarangay
              : null,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isEditable ? accentColor : textSecondary,
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: cardBg,
          onChanged: isEditable
              ? (String? newValue) {
                  setState(() {
                    _selectedBarangay = newValue;
                  });
                }
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: isEditable ? accentColor : textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: isEditable ? Colors.transparent : inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: accentColor.withAlpha(30),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isEditable
                    ? accentColor.withAlpha(102)
                    : accentColor.withAlpha(30),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
          hint: Text(
            "Choose your barangay",
            style: TextStyle(
              color: textSecondary.withAlpha(179),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: barangayOptions.map((String barangay) {
            return DropdownMenuItem<String>(
              value: barangay,
              child: Text(
                barangay,
                style: TextStyle(color: textPrimary),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}