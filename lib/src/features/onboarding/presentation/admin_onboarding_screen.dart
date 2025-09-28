import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import '../../../core/snackbars/loaders.dart';
import '../data/onboarding_repository.dart';

/// Admin screen for managing onboarding status across all users
class AdminOnboardingScreen extends StatefulWidget {
  const AdminOnboardingScreen({super.key});

  @override
  State<AdminOnboardingScreen> createState() => _AdminOnboardingScreenState();
}

class _AdminOnboardingScreenState extends State<AdminOnboardingScreen> {
  final OnboardingRepository _repository = OnboardingRepository();
  Map<String, int>? _statistics;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _repository.getOnboardingStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to load statistics: $e',
        );
      }
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _resetUserOnboarding(String userId, String userEmail) async {
    try {
      await _repository.adminResetOnboardingForUser(userId);
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Reset Successful',
          message: 'Onboarding reset for $userEmail',
        );
        _loadStatistics(); // Refresh stats
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Reset Failed',
          message: 'Failed to reset onboarding: $e',
        );
      }
    }
  }

  Future<void> _markUserOnboardingCompleted(String userId, String userEmail) async {
    try {
      await _repository.adminMarkOnboardingCompletedForUser(userId);
      if (mounted) {
        Loaders.successSnackBar(
          context,
          title: 'Marked Complete',
          message: 'Onboarding completed for $userEmail',
        );
        _loadStatistics(); // Refresh stats
      }
    } catch (e) {
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Update Failed',
          message: 'Failed to update onboarding: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Admin Onboarding Manager',
          style: context.textTheme.headlineSmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppConstants.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Section
              _buildStatisticsSection(),
              
              SizedBox(height: AppConstants.spacingXL),
              
              // Users List Section
              _buildUsersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusLG,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.chart_1,
                  color: context.colorScheme.primary,
                ),
                SizedBox(width: AppConstants.spacingSM),
                Text(
                  'Onboarding Statistics',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppConstants.spacingMD),
            
            if (_isLoadingStats)
              const Center(child: CircularProgressIndicator())
            else if (_statistics != null)
              Column(
                children: [
                  _StatisticTile(
                    icon: Iconsax.people,
                    title: 'Total Users',
                    value: _statistics!['totalUsers'].toString(),
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  _StatisticTile(
                    icon: Iconsax.tick_circle,
                    title: 'Completed Onboarding',
                    value: _statistics!['completedOnboarding'].toString(),
                    color: Colors.green,
                  ),
                  SizedBox(height: AppConstants.spacingSM),
                  _StatisticTile(
                    icon: Iconsax.clock,
                    title: 'Pending Onboarding',
                    value: _statistics!['pendingOnboarding'].toString(),
                    color: Colors.orange,
                  ),
                ],
              )
            else
              Text(
                'Unable to load statistics',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: context.radiusLG,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.people,
                  color: context.colorScheme.primary,
                ),
                SizedBox(width: AppConstants.spacingSM),
                Text(
                  'All Users',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: AppConstants.spacingMD),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repository.getAllUsersOnboardingStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: context.colorScheme.error,
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        Text(
                          'Error loading users: ${snapshot.error}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.user_octagon,
                          size: 48,
                          color: context.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(height: AppConstants.spacingSM),
                        Text(
                          'No users found',
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: context.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final users = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (context, index) => SizedBox(height: AppConstants.spacingSM),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserTile(
                      user: user,
                      onReset: () => _resetUserOnboarding(user['userId'], user['email']),
                      onMarkComplete: () => _markUserOnboardingCompleted(user['userId'], user['email']),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatisticTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: context.radiusMD,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Text(
              title,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onReset;
  final VoidCallback onMarkComplete;

  const _UserTile({
    required this.user,
    required this.onReset,
    required this.onMarkComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = user['onboardingCompleted'] as bool;
    final email = user['email'] as String;
    final fullName = user['fullName'] as String;
    final status = user['status'] as String;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: context.radiusMD,
        border: Border.all(
          color: context.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isCompleted ? Colors.green : Colors.orange,
                child: Icon(
                  isCompleted ? Iconsax.tick_circle : Iconsax.clock,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: AppConstants.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown User',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      email,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingSM,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: context.radiusSM,
                ),
                child: Text(
                  status.toUpperCase(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.spacingMD),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCompleted ? onReset : null,
                  icon: const Icon(Iconsax.refresh, size: 16),
                  label: Text(
                    'Reset',
                    style: context.textTheme.labelMedium,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                    side: BorderSide(color: context.colorScheme.error.withOpacity(0.5)),
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spacingSM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !isCompleted ? onMarkComplete : null,
                  icon: const Icon(Iconsax.tick_circle, size: 16),
                  label: Text(
                    'Complete',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'terminated':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}