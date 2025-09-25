import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/data/models/occupant_model.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/auth_repository.dart';

// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

// Current User Profile Provider - Streams the current user's profile data
final userProfileProvider = StreamProvider<UserModel>((ref) async* {
  final userRepository = ref.watch(userRepositoryProvider);
  final authUser = AuthRepository.instance.authUser;
  
  if (authUser == null) {
    yield UserModel.empty();
    return;
  }

  try {
    final userModel = await userRepository.fetchUserDetails();
    yield userModel;
  } catch (e) {
    yield UserModel.empty();
  }
});

// Future User Profile Provider - For one-time fetches
final userProfileFutureProvider = FutureProvider<UserModel>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.fetchUserDetails();
});

// Occupants Provider - Streams the current user's occupants
final occupantsProvider = StreamProvider<List<OccupantModel>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.streamOccupants();
});

// Occupants Future Provider - For one-time fetches
final occupantsFutureProvider = FutureProvider<List<OccupantModel>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.fetchOccupants();
});

// User Profile State Notifier for managing profile updates
class UserProfileNotifier extends StateNotifier<AsyncValue<UserModel>> {
  final UserRepository _userRepository;
  final Ref _ref;

  UserProfileNotifier(this._userRepository, this._ref) : super(const AsyncValue.loading()) {
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userModel = await _userRepository.fetchUserDetails();
      state = AsyncValue.data(userModel);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Update user profile fields
  Future<void> updateProfileField(Map<String, dynamic> fields) async {
    state = const AsyncValue.loading();
    
    try {
      await _userRepository.updateUserProfileField(fields);
      
      // Refresh the user profile data
      await _loadUserProfile();
      
      // Also refresh the stream provider
      _ref.invalidate(userProfileProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Update profile picture
  Future<void> updateProfilePicture(String imageUrl) async {
    await updateProfileField({'profilePicture': imageUrl});
  }

  // Refresh profile data
  Future<void> refresh() async {
    await _loadUserProfile();
  }
}

// User Profile State Notifier Provider
final userProfileNotifierProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<UserModel>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserProfileNotifier(userRepository, ref);
});

// Occupants State Notifier for managing occupants
class OccupantsNotifier extends StateNotifier<AsyncValue<List<OccupantModel>>> {
  final UserRepository _userRepository;
  final Ref _ref;

  OccupantsNotifier(this._userRepository, this._ref) : super(const AsyncValue.loading()) {
    _loadOccupants();
  }

  Future<void> _loadOccupants() async {
    try {
      final occupants = await _userRepository.fetchOccupants();
      state = AsyncValue.data(occupants);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Add new occupant
  Future<void> addOccupant(OccupantModel occupant) async {
    state = const AsyncValue.loading();
    
    try {
      await _userRepository.addOccupant(occupant);
      await _loadOccupants();
      
      // Also refresh the stream provider
      _ref.invalidate(occupantsProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Update existing occupant
  Future<void> updateOccupant(String occupantId, OccupantModel occupant) async {
    state = const AsyncValue.loading();
    
    try {
      await _userRepository.updateOccupant(occupantId, occupant);
      await _loadOccupants();
      
      // Also refresh the stream provider
      _ref.invalidate(occupantsProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Delete occupant
  Future<void> deleteOccupant(String occupantId) async {
    state = const AsyncValue.loading();
    
    try {
      await _userRepository.deleteOccupant(occupantId);
      await _loadOccupants();
      
      // Also refresh the stream provider
      _ref.invalidate(occupantsProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Refresh occupants data
  Future<void> refresh() async {
    await _loadOccupants();
  }
}

// Occupants State Notifier Provider
final occupantsNotifierProvider = StateNotifierProvider<OccupantsNotifier, AsyncValue<List<OccupantModel>>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return OccupantsNotifier(userRepository, ref);
});