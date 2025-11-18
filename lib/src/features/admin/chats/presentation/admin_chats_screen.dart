import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../providers/chats_providers.dart';
import 'chat_conversation_screen.dart';

/// Admin Chat Management Screen
/// Allows admins to view all tenants and communicate with them via chat
class AdminChatsScreen extends ConsumerStatefulWidget {
  const AdminChatsScreen({
    super.key,
    required this.onMenuTap,
  });

  final VoidCallback onMenuTap;

  @override
  ConsumerState<AdminChatsScreen> createState() => _AdminChatsScreenState();
}

class _AdminChatsScreenState extends ConsumerState<AdminChatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final propertiesAsync = ref.watch(propertiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Iconsax.menu,
            color: context.colorScheme.onSurface,
          ),
          tooltip: 'Open navigation menu',
          onPressed: widget.onMenuTap,
        ),
        title: Text(
          'Tenant Chats',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveLayoutWrapper(
          centerContent: true,
          child: Column(
            children: [
              // Search Bar
              _SearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),

              // Property Filter (only show if 2+ properties)
              propertiesAsync.when(
                data: (snapshot) {
                  if (snapshot.docs.length >= 2) {
                    return _PropertyFilter(
                      properties: snapshot.docs,
                      selectedPropertyId: _selectedPropertyId,
                      onPropertySelected: (propertyId) {
                        setState(() {
                          _selectedPropertyId = propertyId;
                        });
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Tenants List
              Expanded(
                child: usersAsync.when(
                  data: (snapshot) {
                    // Filter and sort users
                    var users = snapshot.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) return false;

                      final profile = data['profile'] as Map<String, dynamic>? ?? {};
                      final property = data['property'] as Map<String, dynamic>? ?? {};
                      final firstName = profile['firstName'] as String? ?? '';
                      final lastName = profile['lastName'] as String? ?? '';
                      final email = profile['email'] as String? ?? '';
                      final unitId = property['unitId'] as String? ?? '';
                      final propertyId = property['propertyId'] as String? ?? '';
                      
                      // Filter by selected property (if any)
                      if (_selectedPropertyId != null && propertyId != _selectedPropertyId) {
                        return false;
                      }
                      
                      // Filter by search query (includes unitId now)
                      final searchText = '$firstName $lastName $email $unitId'.toLowerCase();
                      return _searchQuery.isEmpty || searchText.contains(_searchQuery);
                    }).toList();

                    // Natural sort by unitId (numeric sorting within string)
                    users.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>?;
                      final bData = b.data() as Map<String, dynamic>?;
                      final aProperty = aData?['property'] as Map<String, dynamic>? ?? {};
                      final bProperty = bData?['property'] as Map<String, dynamic>? ?? {};
                      final aUnitId = aProperty['unitId'] as String? ?? '';
                      final bUnitId = bProperty['unitId'] as String? ?? '';
                      
                      return _naturalCompare(aUnitId, bUnitId);
                    });

                    if (users.isEmpty) {
                      return _EmptyState(
                        isSearching: _searchQuery.isNotEmpty,
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingSM,
                        vertical: AppConstants.spacingXS,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userData = user.data() as Map<String, dynamic>;
                        
                        return _TenantChatCard(
                          userId: user.id,
                          userData: userData,
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          size: 64,
                          color: context.colorScheme.error,
                        ),
                        SizedBox(height: AppConstants.spacingMD),
                        Text(
                          'Error loading tenants',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        Text(
                          error.toString(),
                          style: context.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Natural sort comparison for strings with numbers
  int _naturalCompare(String a, String b) {
    final regex = RegExp(r'(\d+)');
    final aMatches = regex.allMatches(a).toList();
    final bMatches = regex.allMatches(b).toList();

    if (aMatches.isEmpty || bMatches.isEmpty) {
      return a.compareTo(b);
    }

    // Extract the first number from each string
    final aNum = int.tryParse(aMatches.first.group(0) ?? '') ?? 0;
    final bNum = int.tryParse(bMatches.first.group(0) ?? '') ?? 0;

    return aNum.compareTo(bNum);
  }
}

// Search Bar Widget
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search tenants...',
          hintStyle: TextStyle(
            fontFamily: 'Montserrat',
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Iconsax.search_normal,
            color: context.colorScheme.primary,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Iconsax.close_circle,
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: context.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: context.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

// Tenant Chat Card Widget
class _TenantChatCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _TenantChatCard({
    required this.userId,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final profile = userData['profile'] as Map<String, dynamic>? ?? {};
    final property = userData['property'] as Map<String, dynamic>? ?? {};
    
    final firstName = profile['firstName'] as String? ?? '';
    final lastName = profile['lastName'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final profilePicture = profile['profilePicture'] as String? ?? '';
    final unitId = property['unitId'] as String? ?? 'No Unit';

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXS,
        vertical: AppConstants.spacingXS / 2,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatConversationScreen(
                userId: userId,
                userName: '$firstName $lastName'.trim(),
                userEmail: email,
                unitId: unitId,
                profilePicture: profilePicture,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingSM),
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 28,
                backgroundColor: context.colorScheme.primaryContainer,
                backgroundImage: profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture)
                    : null,
                child: profilePicture.isEmpty
                    ? Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: context.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: AppConstants.spacingSM),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName'.trim(),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppConstants.spacingXS / 2),
                    Row(
                      children: [
                        Icon(
                          Iconsax.home_2,
                          size: 14,
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        SizedBox(width: AppConstants.spacingXS / 2),
                        Text(
                          'Unit $unitId',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Iconsax.arrow_right_3,
                color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Iconsax.search_normal : Iconsax.message,
            size: 64,
            color: context.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: AppConstants.spacingMD),
          Text(
            isSearching ? 'No tenants found' : 'No tenants yet',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXL),
            child: Text(
              isSearching
                  ? 'Try adjusting your search criteria'
                  : 'Tenants will appear here once they are registered',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Property Filter Widget
class _PropertyFilter extends StatelessWidget {
  final List<QueryDocumentSnapshot> properties;
  final String? selectedPropertyId;
  final ValueChanged<String?> onPropertySelected;

  const _PropertyFilter({
    required this.properties,
    required this.selectedPropertyId,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMD,
        vertical: AppConstants.spacingXS,
      ),
      child: selectedPropertyId == null
          ? _buildDropdown(context)
          : _buildSelectedChip(context),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSM),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: selectedPropertyId,
        hint: Row(
          children: [
            Icon(
              Iconsax.building,
              size: 18,
              color: context.colorScheme.primary,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Text(
              'Filter by Property',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: properties.map((property) {
          final data = property.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? 'Unknown Property';
          return DropdownMenuItem(
            value: property.id,
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onPropertySelected,
      ),
    );
  }

  Widget _buildSelectedChip(BuildContext context) {
    QueryDocumentSnapshot? selectedProperty;
    try {
      selectedProperty = properties.firstWhere(
        (p) => p.id == selectedPropertyId,
      );
    } catch (e) {
      // If property not found, clear the selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onPropertySelected(null);
      });
      return const SizedBox.shrink();
    }

    final data = selectedProperty.data() as Map<String, dynamic>;
    final name = data['name'] as String? ?? 'Unknown Property';

    return Chip(
      avatar: Icon(
        Iconsax.building,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        name,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: context.colorScheme.primary,
      deleteIcon: Icon(Iconsax.close_circle, color: Colors.white, size: 18),
      onDeleted: () => onPropertySelected(null),
    );
  }
}
