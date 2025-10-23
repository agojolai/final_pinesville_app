import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/snackbars/loaders.dart';
import '../../../core/utils/app_logger.dart';
import '../../admin/chats/domain/chat_model.dart';
import '../providers/tenant_chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with TickerProviderStateMixin {
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
    
    // Auto-scroll to bottom on initial load and keyboard appearance
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    final messageText = _messageController.text.trim();
    _messageController.clear();
    
    if (mounted) {
      setState(() {
        _isTyping = false;
        _isSending = true;
      });
    }
    
    try {
      final repository = ref.read(tenantChatRepositoryProvider);
      await repository.sendMessage(text: messageText);
      
      _scrollToBottom();
      
      AppLogger.info('Message sent successfully');
    } catch (e) {
      AppLogger.error('Error sending message', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to send message. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickImage() async {
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
    if (mounted) {
      setState(() => _isSending = true);
    }

    try {
      // Upload image first
      final repository = ref.read(tenantChatRepositoryProvider);
      final imageUrl = await repository.uploadImage(imageFile);
      
      // Send message with imageUrl (text can be empty for image-only messages)
      await repository.sendMessage(text: '', imageUrl: imageUrl);

      _scrollToBottom();
      
      AppLogger.info('Image sent successfully');
    } catch (e) {
      AppLogger.error('Error sending image', e);
      if (mounted) {
        Loaders.errorSnackBar(
          context,
          title: 'Error',
          message: 'Failed to send image. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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
      final repository = ref.read(tenantChatRepositoryProvider);
      
      AppLogger.info('Starting video upload...');
      final videoUrl = await repository.uploadVideo(videoFile);
      
      AppLogger.info('Video uploaded successfully: $videoUrl');
      
      // Send message with videoUrl
      await repository.sendMessage(text: '', videoUrl: videoUrl);

      _scrollToBottom();
      
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

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(tenantMessagesStreamProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        toolbarHeight: AppConstants.appBarHeight,
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (snapshot) {
                final messages = snapshot.docs
                    .map((doc) => ChatMessage.fromFirestore(doc))
                    .toList();

                if (messages.isEmpty) {
                  return _EmptyMessagesWidget();
                }

                // Scroll to bottom whenever messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(animate: false);
                });

                return _MessageList(
                  messages: messages,
                  scrollController: _scrollController,
                  currentUserId: currentUserId,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                AppLogger.error('Error loading messages', error, stack);
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 48,
                        color: context.colorScheme.error,
                      ),
                      SizedBox(height: AppConstants.spacingSM),
                      Text(
                        'Failed to load messages',
                        style: context.textTheme.titleMedium,
                      ),
                      SizedBox(height: AppConstants.spacingXS),
                      Text(
                        error.toString(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _MessageInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSendMessage: _sendMessage,
            onPickImage: _pickImage,
            onPickVideo: _pickVideo,
            isTyping: _isTyping,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }
}

// Empty messages widget
class _EmptyMessagesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.message,
            size: 64,
            color: context.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: AppConstants.spacingSM),
          Text(
            'No messages yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppConstants.spacingXS),
          Text(
            'Start a conversation with admin',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Message List Widget
class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final String currentUserId;

  const _MessageList({
    required this.messages,
    required this.scrollController,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: AppConstants.spacingSM,
        right: AppConstants.spacingSM,
        top: AppConstants.spacingSM,
        bottom: AppConstants.spacingLG, // Extra bottom padding
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      reverse: false,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showTimestamp = index == 0 || 
            _shouldShowTimestamp(messages[index - 1], message);
        
        return AnimatedContainer(
          duration: AppConstants.durationFast,
          curve: AppConstants.curveDefault,
          child: Column(
            children: [
              if (showTimestamp) _TimestampWidget(timestamp: message.timestamp),
              _MessageBubble(
                message: message,
                showAnimation: index == messages.length - 1,
                isFromMe: message.senderId == currentUserId,
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowTimestamp(ChatMessage previous, ChatMessage current) {
    final diff = current.timestamp.difference(previous.timestamp);
    return diff.inMinutes > 5;
  }
}

// Enhanced Message Bubble Widget
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAnimation;
  final bool isFromMe;

  const _MessageBubble({
    required this.message,
    this.showAnimation = false,
    required this.isFromMe,
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
    final hasText = widget.message.text.isNotEmpty;
    final hasImage = widget.message.imageUrl != null && widget.message.imageUrl!.isNotEmpty;
    final hasVideo = widget.message.videoUrl != null && widget.message.videoUrl!.isNotEmpty;
    
    return Align(
      alignment: widget.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppConstants.spacingXS,
          horizontal: AppConstants.spacingMD,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: widget.isFromMe 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingSM,
              ),
              decoration: BoxDecoration(
                color: widget.isFromMe
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: widget.isFromMe 
                      ? const Radius.circular(16) 
                      : Radius.zero,
                  bottomRight: widget.isFromMe 
                      ? Radius.zero 
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withValues(alpha:0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage) ...[
                    _ImageMessage(message: widget.message),
                    if (hasText) SizedBox(height: AppConstants.spacingXS),
                  ],
                  if (hasVideo) ...[
                    _VideoMessage(message: widget.message),
                    if (hasText) SizedBox(height: AppConstants.spacingXS),
                  ],
                  if (hasText)
                    Text(
                      widget.message.text,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: widget.isFromMe
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(widget.message.timestamp),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha:0.6),
                    fontSize: 11,
                  ),
                ),
                // Don't show status icon for now since we're using real-time sync
                // Messages are immediately visible when sent
              ],
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

// Enhanced Image Message Widget
class _ImageMessage extends StatelessWidget {
  final ChatMessage message;

  const _ImageMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _showImagePreview(context),
        onLongPress: () => _showImageOptions(context),
        child: Hero(
          tag: 'image_${message.id}',
          child: Image.network(
            message.imageUrl!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppConstants.durationFast,
                curve: Curves.easeOut,
                child: child,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                child: Center(
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
                        Iconsax.image,
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
                  tag: 'image_${message.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.imageUrl!,
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
                  color: Colors.black.withValues(alpha:0.6),
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
                  color: context.colorScheme.onSurface.withValues(alpha:0.2),
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
                          color: context.colorScheme.onSurface.withValues(alpha:0.6),
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
                          color: context.colorScheme.onSurface.withValues(alpha:0.6),
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

      await dio.download(message.imageUrl!, filePath);
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
  final ChatMessage message;

  const _VideoMessage({required this.message});

  @override
  State<_VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<_VideoMessage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.message.videoUrl!))
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
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.message.videoUrl!));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VideoPlayerDialog(
        controller: controller,
        videoUrl: widget.message.videoUrl!,
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

      await dio.download(widget.message.videoUrl!, filePath);
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

// Timestamp Widget
class _TimestampWidget extends StatelessWidget {
  final DateTime timestamp;

  const _TimestampWidget({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppConstants.spacingSM),
      child: Text(
        _formatTimestamp(timestamp),
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurface.withValues(alpha:0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Enhanced Message Input Widget
class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final bool isTyping;
  final bool isSending;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickVideo,
    required this.isTyping,
    required this.isSending,
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
            color: context.colorScheme.outline.withValues(alpha:0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withValues(alpha:0.05),
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
              onPressed: widget.onPickImage,
              isLoading: widget.isSending,
            ),
            SizedBox(width: AppConstants.spacingXS),
            _AttachmentButton(
              icon: Iconsax.video,
              onPressed: widget.onPickVideo,
              isLoading: widget.isSending,
            ),
            SizedBox(width: AppConstants.spacingXS),
            Expanded(
              child: _MessageTextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onSubmitted: widget.onSendMessage,
              ),
            ),
            SizedBox(width: AppConstants.spacingXS),
            AnimatedBuilder(
              animation: _sendButtonScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScale.value,
                  child: _SendButton(
                    onPressed: widget.onSendMessage,
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
              color: context.colorScheme.onSurface.withValues(alpha:0.7),
            ),
      style: IconButton.styleFrom(
        backgroundColor: context.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(AppConstants.spacingSM),
      ),
    );
  }
}

// Message Text Field Widget
class _MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  const _MessageTextField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: 'Message...',
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurface.withValues(alpha:0.6),
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
      onSubmitted: (_) => onSubmitted(),
      maxLines: 4,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
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
            : context.colorScheme.onSurface.withValues(alpha:0.5),
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
