import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../theme/app_constants.dart';
import '../../../../theme/theme_extensions.dart';
import '../../../../core/snackbars/loaders.dart';
import '../../../../core/utils/app_logger.dart';
import '../providers/chats_providers.dart';
import '../domain/chat_model.dart';
import '../../../../core/repositories/auth_repository.dart';

/// Individual Chat Conversation Screen
/// Displays messages between admin and a specific tenant
class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.unitId,
    this.profilePicture,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final String unitId;
  final String? profilePicture;

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    
    // Auto-scroll to bottom on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay to ensure messages are loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottom(animate: false);
      });
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_isTyping != hasText) {
      setState(() => _isTyping = hasText);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        // Add small delay to ensure layout is complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && mounted) {
            final maxScroll = _scrollController.position.maxScrollExtent;
            if (animate) {
              _scrollController.animateTo(
                maxScroll,
                duration: AppConstants.durationFast,
                curve: AppConstants.curveDefault,
              );
            } else {
              _scrollController.jumpTo(maxScroll);
            }
          }
        });
      }
    });
  }

  Future<void> _sendMessage({String? imageUrl, String? videoUrl}) async {
    final message = _messageController.text.trim();
    
    if (message.isEmpty && imageUrl == null) {
      AppLogger.debug('Cannot send empty message without image');
      return;
    }
    if (_isSending) {
      AppLogger.debug('Already sending a message, skipping');
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() => _isSending = true);

    try {
      final repository = ref.read(chatsRepositoryProvider);
      final chatId = 'chat_${widget.userId}';
      // Resolve admin identity
      final authUser = AuthRepository.instance.authUser;
      final adminUid = authUser?.uid ?? 'admin';
      String adminName = 'Admin';
      try {
        final info = await repository.getAdminInfo(adminUid);
        if (info != null) {
          final candidate = (info['name'] as String?)?.trim();
          if (candidate != null && candidate.isNotEmpty) {
            adminName = candidate;
          } else {
            adminName = authUser?.email ?? 'Admin';
          }
        } else {
          adminName = authUser?.email ?? 'Admin';
        }
      } catch (_) {
        adminName = authUser?.email ?? 'Admin';
      }
      
      AppLogger.info('Sending message - chatId: $chatId, hasText: ${message.isNotEmpty}, hasImage: ${imageUrl != null}, senderId: $adminUid');
      
      await repository.sendMessage(
        chatId: chatId,
        text: message.isNotEmpty ? message : '',
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        senderId: adminUid,
        senderName: adminName,
        senderType: 'admin',
      );

      AppLogger.info('Message sent successfully to Firebase');

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      AppLogger.error('Error sending message', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to send message: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Show preview dialog before sending
      if (mounted) {
        final shouldSend = await _showImagePreviewBeforeSend(context, File(image.path));
        
        if (shouldSend == true) {
          await _sendImageMessage(File(image.path));
        }
      }
    } catch (e) {
      AppLogger.error('Error picking image', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to pick image. Please try again.',
        );
      }
    }
  }

  Future<bool?> _showImagePreviewBeforeSend(BuildContext context, File imageFile) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(AppConstants.spacingMD),
        child: Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.gallery,
                      color: context.colorScheme.primary,
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Text(
                      'Preview Image',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // Image Preview
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacingSM),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.send_2, size: 18),
                            SizedBox(width: AppConstants.spacingXS),
                            Text(
                              'Send',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendImageMessage(File imageFile) async {
    try {
      final repository = ref.read(chatsRepositoryProvider);
      
      AppLogger.info('Starting image upload...');
      final imageUrl = await repository.uploadImage(
        imageFile,
        widget.userId,
      );

      AppLogger.info('Image uploaded successfully: $imageUrl');
      
      // _sendMessage handles its own _isSending state
      await _sendMessage(imageUrl: imageUrl);
      
    } catch (e) {
      AppLogger.error('Error uploading image', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to upload image. Please try again.',
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) {
        return;
      }

      // Haptic feedback
      HapticFeedback.selectionClick();

      // Show preview dialog before sending
      if (mounted) {
        final shouldSend = await _showVideoPreviewBeforeSend(context, File(video.path));
        
        if (shouldSend == true) {
          await _sendVideoMessage(File(video.path));
        }
      }
    } catch (e) {
      AppLogger.error('Error picking video', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to pick video. Please try again.',
        );
      }
    }
  }

  Future<bool?> _showVideoPreviewBeforeSend(BuildContext context, File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      await controller.initialize();
      
      return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _VideoPreviewDialog(
          controller: controller,
          onCancel: () {
            controller.dispose();
            Navigator.of(context).pop(false);
          },
          onSend: () {
            controller.dispose();
            Navigator.of(context).pop(true);
          },
        ),
      );
    } catch (e) {
      AppLogger.error('Error initializing video preview', e);
      
      // If preview fails, ask user if they want to send anyway
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Preview Unavailable'),
          content: Text('Cannot preview this video, but you can still send it. Would you like to send it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Send Anyway'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendVideoMessage(File videoFile) async {
    if (mounted) {
      setState(() => _isSending = true);
    }

    try {
      final repository = ref.read(chatsRepositoryProvider);
      
      AppLogger.info('Starting video upload...');
      final videoUrl = await repository.uploadVideo(videoFile, widget.userId);
      
      AppLogger.info('Video uploaded successfully: $videoUrl');
      
      // Send message with videoUrl
      await _sendMessage(videoUrl: videoUrl);
      
      AppLogger.info('Video sent successfully');
    } catch (e) {
      AppLogger.error('Error sending video', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to send video. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use chat_ prefix for chatId to match Firestore structure
    final chatId = 'chat_${widget.userId}';
    final messagesAsync = ref.watch(messagesStreamProvider(chatId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left,
            color: context.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.colorScheme.primaryContainer,
              backgroundImage: widget.profilePicture?.isNotEmpty == true
                  ? NetworkImage(widget.profilePicture!)
                  : null,
              child: widget.profilePicture?.isEmpty != false
                  ? Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'T',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: AppConstants.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Unit ${widget.unitId}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (snapshot) {
                AppLogger.debug('Messages snapshot received: ${snapshot.docs.length} documents');
                
                final messages = snapshot.docs
                    .map((doc) {
                      try {
                        return ChatMessage.fromFirestore(doc);
                      } catch (e) {
                        AppLogger.error('Error parsing message ${doc.id}', e);
                        return null;
                      }
                    })
                    .whereType<ChatMessage>()
                    .toList(); // No need to sort - already in ascending order from Firestore

                AppLogger.debug('Parsed ${messages.length} messages successfully');

                if (messages.isEmpty) {
                  return _EmptyMessagesState();
                }

                // Scroll to bottom whenever messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(animate: false);
                });

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: AppConstants.spacingSM,
                    right: AppConstants.spacingSM,
                    top: AppConstants.spacingSM,
                    bottom: AppConstants.spacingLG, // Extra bottom padding
                  ),
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdmin = message.senderType == 'admin';
                    final showTimestamp = index == 0 ||
                        !_isSameDay(
                          messages[index - 1].timestamp,
                          message.timestamp,
                        );

                    return AnimatedContainer(
                      duration: AppConstants.durationFast,
                      curve: AppConstants.curveDefault,
                      child: Column(
                        children: [
                          if (showTimestamp) _TimestampDivider(timestamp: message.timestamp),
                          _MessageBubble(
                            message: message,
                            isAdmin: isAdmin,
                            showAnimation: index == messages.length - 1,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) {
                AppLogger.error('Error loading messages', error);
                AppLogger.debug('Stack trace: $stack');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 48,
                        color: context.colorScheme.error,
                      ),
                      SizedBox(height: AppConstants.spacingMD),
                      Text(
                        'Error loading messages',
                        style: context.textTheme.titleMedium,
                      ),
                      SizedBox(height: AppConstants.spacingSM),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMD),
                        child: Text(
                          error.toString(),
                          style: context.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message Input
          _MessageInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: () => _sendMessage(),
            onImagePick: _pickAndSendImage,
            onVideoPick: _pickVideo,
            isTyping: _isTyping,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime previous, DateTime current) {
    return previous.year == current.year &&
        previous.month == current.month &&
        previous.day == current.day;
  }
}

// Timestamp Divider Widget
class _TimestampDivider extends StatelessWidget {
  final DateTime timestamp;

  const _TimestampDivider({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      child: Text(
        _formatTimestamp(timestamp),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Enhanced Message Bubble Widget with Animation
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isAdmin;
  final bool showAnimation;

  const _MessageBubble({
    required this.message,
    required this.isAdmin,
    this.showAnimation = false,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.durationNormal,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppConstants.curveDefault,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildBubble(context),
          ),
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Align(
      alignment: widget.isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppConstants.spacingXS,
          horizontal: AppConstants.spacingMD,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: widget.isAdmin 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            // Sender name display (like Meta Business Suite)
            if (widget.message.senderName != null && widget.message.senderName!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  left: widget.isAdmin ? 0 : AppConstants.spacingXS,
                  right: widget.isAdmin ? AppConstants.spacingXS : 0,
                  bottom: AppConstants.spacingXS / 2,
                ),
                child: Text(
                  widget.message.senderName!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                    //fontWeight: FontWeight.w600,
                    fontSize: 8.5,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingSM,
              ),
              decoration: BoxDecoration(
                color: widget.isAdmin
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: widget.isAdmin 
                      ? const Radius.circular(16) 
                      : Radius.zero,
                  bottomRight: widget.isAdmin 
                      ? Radius.zero 
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.imageUrl != null) ...[
                    _ImageMessage(
                      imageUrl: widget.message.imageUrl!,
                      messageId: widget.message.id,
                    ),
                    if (widget.message.text.isNotEmpty) 
                      SizedBox(height: AppConstants.spacingXS),
                  ],
                  if (widget.message.videoUrl != null) ...[
                    _VideoMessage(
                      videoUrl: widget.message.videoUrl!,
                      messageId: widget.message.id,
                    ),
                    if (widget.message.text.isNotEmpty) 
                      SizedBox(height: AppConstants.spacingXS),
                  ],
                  if (widget.message.text.isNotEmpty)
                    Text(
                      widget.message.text,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: widget.isAdmin
                            ? Colors.white
                            : context.colorScheme.onSurface,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppConstants.spacingXS / 2),
            Text(
              _formatTime(widget.message.timestamp),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

// Image Message Widget
class _ImageMessage extends StatelessWidget {
  final String imageUrl;
  final String messageId;

  const _ImageMessage({
    required this.imageUrl,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showImagePreview(context),
        onLongPress: () => _showImageOptions(context),
        child: Hero(
          tag: 'chat_image_$messageId',
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return AnimatedOpacity(
                opacity: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : 0,
                duration: AppConstants.durationFast,
                curve: Curves.easeOut,
                child: Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: context.colorScheme.errorContainer,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.gallery_slash,
                        color: context.colorScheme.onErrorContainer,
                        size: 32,
                      ),
                      SizedBox(height: AppConstants.spacingXS),
                      Text(
                        'Image not available',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Hero(
                  tag: 'chat_image_$messageId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _downloadImage(context);
                  },
                  icon: const Icon(
                    Iconsax.document_download,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Download Image',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppConstants.spacingSM),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.eye,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        'View Image',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Open in full screen',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showImagePreview(context);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppConstants.spacingSM),
                        decoration: BoxDecoration(
                          color: context.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.document_download,
                          color: context.colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        'Download Image',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Save to your gallery',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _downloadImage(context);
                      },
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context) async {
    try {
      if (!context.mounted) return;
      
      Loaders.infoSnackBar(
        context,
        title: 'Downloading',
        message: 'Downloading image...',
      );

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';

      await dio.download(imageUrl, filePath);
      await Gal.putImage(filePath);

      if (!context.mounted) return;
      
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Image downloaded successfully',
      );
    } catch (e) {
      AppLogger.error('Error downloading image', e);
      
      if (!context.mounted) return;
      
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to download image. Please try again.',
      );
    }
  }
}

// Video Message Widget
class _VideoMessage extends StatefulWidget {
  final String videoUrl;
  final String messageId;

  const _VideoMessage({
    required this.videoUrl,
    required this.messageId,
  });

  @override
  State<_VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<_VideoMessage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showVideoPlayer(context),
        onLongPress: () => _showVideoOptions(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            else
              Container(
                height: 200,
                color: context.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(AppConstants.spacingSM),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoPlayer(BuildContext context) {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VideoPlayerDialog(
        controller: controller,
        videoUrl: widget.videoUrl,
      ),
    );
  }

  void _showVideoOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppConstants.spacingMD),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppConstants.spacingSM),
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.video,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        'Play Video',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Open in full screen',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showVideoPlayer(context);
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppConstants.spacingSM),
                        decoration: BoxDecoration(
                          color: context.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Iconsax.document_download,
                          color: context.colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        'Download Video',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Save to your gallery',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _downloadVideo(context);
                      },
                    ),
                    SizedBox(height: AppConstants.spacingSM),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadVideo(BuildContext context) async {
    try {
      if (!context.mounted) return;
      
      Loaders.infoSnackBar(
        context,
        title: 'Downloading',
        message: 'Downloading video...',
      );

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${tempDir.path}/$fileName';

      await dio.download(widget.videoUrl, filePath);
      await Gal.putVideo(filePath);

      if (!context.mounted) return;
      
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Video downloaded successfully',
      );
    } catch (e) {
      AppLogger.error('Error downloading video', e);
      
      if (!context.mounted) return;
      
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to download video. Please try again.',
      );
    }
  }
}

// Video Preview Dialog (for sending)
class _VideoPreviewDialog extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _VideoPreviewDialog({
    required this.controller,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  @override
  Widget build(BuildContext context) {
    final isInitialized = widget.controller.value.isInitialized;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppConstants.spacingMD),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: Row(
                children: [
                  Icon(
                    Iconsax.video,
                    color: context.colorScheme.primary,
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Text(
                    'Preview Video',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Video Preview
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isInitialized
                    ? AspectRatio(
                        aspectRatio: widget.controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(widget.controller),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (widget.controller.value.isPlaying) {
                                    widget.controller.pause();
                                  } else {
                                    widget.controller.play();
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(AppConstants.spacingSM),
                                child: Icon(
                                  widget.controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
            // Action Buttons
            Padding(
              padding: EdgeInsets.all(AppConstants.spacingMD),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacingSM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSend,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.send_2, size: 18),
                          SizedBox(width: AppConstants.spacingXS),
                          Text(
                            'Send',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video Player Dialog (for viewing)
class _VideoPlayerDialog extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoUrl;

  const _VideoPlayerDialog({
    required this.controller,
    required this.videoUrl,
  });

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.controller.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        widget.controller.play();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          if (_isInitialized)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (widget.controller.value.isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: widget.controller.value.aspectRatio,
                    child: VideoPlayer(widget.controller),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Close',
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 72,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () async {
                  await _downloadVideo(context);
                },
                icon: const Icon(
                  Iconsax.document_download,
                  color: Colors.white,
                  size: 24,
                ),
                tooltip: 'Download Video',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadVideo(BuildContext context) async {
    try {
      if (!context.mounted) return;
      
      Loaders.infoSnackBar(
        context,
        title: 'Downloading',
        message: 'Downloading video...',
      );

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${tempDir.path}/$fileName';

      await dio.download(widget.videoUrl, filePath);
      await Gal.putVideo(filePath);

      if (!context.mounted) return;
      
      Loaders.successSnackBar(
        context,
        title: 'Success',
        message: 'Video downloaded successfully',
      );
    } catch (e) {
      AppLogger.error('Error downloading video', e);
      
      if (!context.mounted) return;
      
      Loaders.errorSnackBar(
        context,
        title: 'Error',
        message: 'Failed to download video. Please try again.',
      );
    }
  }
}

// Enhanced Message Input Widget
class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onImagePick;
  final VoidCallback onVideoPick;
  final bool isTyping;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onImagePick,
    required this.onVideoPick,
    required this.isTyping,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      duration: AppConstants.durationFast,
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _AttachmentButton(
              icon: Iconsax.gallery,
              onPressed: widget.onImagePick,
              isLoading: widget.isSending,
            ),
            SizedBox(width: AppConstants.spacingXS),
            _AttachmentButton(
              icon: Iconsax.video,
              onPressed: widget.onVideoPick,
              isLoading: widget.isSending,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isSending,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'Montserrat',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: context.colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingSM,
                    vertical: AppConstants.spacingSM,
                  ),
                ),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Montserrat',
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
              ),
            ),
            SizedBox(width: AppConstants.spacingXS),
            AnimatedBuilder(
              animation: _sendButtonScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScale.value,
                  child: _SendButton(
                    onPressed: widget.onSend,
                    isActive: widget.isTyping,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Attachment Button Widget
class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AttachmentButton({
    required this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colorScheme.primary,
                ),
              ),
            )
          : Icon(
              icon,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      style: IconButton.styleFrom(
        backgroundColor: context.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(AppConstants.spacingSM),
      ),
    );
  }
}

// Send Button Widget
class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;

  const _SendButton({
    required this.onPressed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        Iconsax.send_2,
        color: isActive 
            ? Colors.white 
            : context.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      style: IconButton.styleFrom(
        backgroundColor: isActive 
            ? context.colorScheme.primary 
            : context.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(AppConstants.spacingSM),
      ),
    );
  }
}

// Empty Messages State with Sample Messages
class _EmptyMessagesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample messages to show UI preview
    final sampleMessages = [
      ChatMessage(
        id: 'sample1',
        text: 'Hello! I have a question about my bill for this month.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        senderId: 'tenant',
        senderName: 'Tenant',
        senderType: 'tenant',
      ),
      ChatMessage(
        id: 'sample2',
        text: 'Hi! Of course, I\'d be happy to help. What would you like to know?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        senderId: 'admin',
        senderName: 'Admin',
        senderType: 'admin',
      ),
      ChatMessage(
        id: 'sample3',
        text: 'I noticed there\'s an additional charge. Can you explain what it\'s for?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderId: 'tenant',
        senderName: 'Tenant',
        senderType: 'tenant',
      ),
    ];

    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spacingSM),
      physics: const BouncingScrollPhysics(),
      itemCount: sampleMessages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TimestampDivider(timestamp: sampleMessages[0].timestamp);
        }
        
        final message = sampleMessages[index - 1];
        final isAdmin = message.senderType == 'admin';
        
        return _MessageBubble(
          message: message,
          isAdmin: isAdmin,
          showAnimation: false,
        );
      },
    );
  }
}
