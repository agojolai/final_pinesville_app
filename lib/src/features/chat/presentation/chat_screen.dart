import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import '../../../theme/app_constants.dart';
import '../../../theme/theme_extensions.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/snackbars/loaders.dart';

// Chat Message Model
class ChatMessage {
  final String id;
  final String text;
  final String? imagePath;
  final DateTime timestamp;
  final bool isFromMe;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    this.text = '',
    this.imagePath,
    required this.timestamp,
    required this.isFromMe,
    this.status = MessageStatus.sent,
  });

  bool get hasText => text.isNotEmpty;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? text,
    String? imagePath,
    DateTime? timestamp,
    bool? isFromMe,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, delivered, read }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _messageFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isTyping = false;
  
  List<ChatMessage> messages = [
    ChatMessage(
      id: '1',
      text: 'Hello Fahime! How was the class?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 24)),
      isFromMe: true,
      status: MessageStatus.delivered,
    ),
    ChatMessage(
      id: '2',
      text: 'Hi Elnaz! Oh it was so boring!',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 12)),
      isFromMe: false,
    ),
    ChatMessage(
      id: '3',
      text: 'Oh! I was sure about that! because Mr. Smith is terrible on teaching.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 12)),
      isFromMe: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    
    // Auto-scroll to bottom on keyboard appearance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
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
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      timestamp: DateTime.now(),
      isFromMe: true,
      status: MessageStatus.sending,
    );
    
    setState(() {
      messages.add(message);
      _messageController.clear();
      _isTyping = false;
    });
    
    _scrollToBottom();
    
    // Simulate message sent with realistic delay
    await Future.delayed(Duration(milliseconds: 300 + (messageText.length * 10)));
    
    if (mounted) {
      setState(() {
        final index = messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          messages[index] = message.copyWith(status: MessageStatus.delivered);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        // Haptic feedback
        HapticFeedback.selectionClick();
        
        final message = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imagePath: image.path,
          timestamp: DateTime.now(),
          isFromMe: true,
          status: MessageStatus.sending,
        );
        
        setState(() {
          messages.add(message);
        });
        
        _scrollToBottom();
        
        // Simulate upload with progress
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          setState(() {
            final index = messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              messages[index] = message.copyWith(status: MessageStatus.delivered);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    Loaders.errorSnackBar(context, title: 'Error', message: message);
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: AppConstants.durationFast,
            curve: AppConstants.curveDefault,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: _MessageList(
              messages: messages,
              scrollController: _scrollController,
            ),
          ),
          _MessageInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSendMessage: _sendMessage,
            onPickImage: _pickImage,
            isTyping: _isTyping,
            isLoading: _isLoading,
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

  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(AppConstants.spacingSM),
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

  const _MessageBubble({
    required this.message,
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
      alignment: widget.message.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppConstants.spacingXS,
          horizontal: AppConstants.spacingMD,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: widget.message.isFromMe 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingSM,
                vertical: AppConstants.spacingSM,
              ),
              decoration: BoxDecoration(
                color: widget.message.isFromMe
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: widget.message.isFromMe 
                      ? const Radius.circular(16) 
                      : Radius.zero,
                  bottomRight: widget.message.isFromMe 
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
                  if (widget.message.hasImage) ...[
                    _ImageMessage(message: widget.message),
                    if (widget.message.hasText) SizedBox(height: AppConstants.spacingXS),
                  ],
                  if (widget.message.hasText)
                    Text(
                      widget.message.text,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: widget.message.isFromMe
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
                if (widget.message.isFromMe) ...[
                  SizedBox(width: AppConstants.spacingXS / 2),
                  _StatusIcon(status: widget.message.status),
                ],
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
          child: Image.file(
            File(message.imagePath!),
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
                    child: Image.file(
                      File(message.imagePath!),
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
      // Show loading indicator
      Loaders.customToast(context, message: 'Downloading image...');

      // Download the image to gallery
      await Gal.putImage(message.imagePath!);
      
      // Haptic feedback for success
      HapticFeedback.heavyImpact();

      // Show success message
      if (context.mounted) {
        Loaders.hideSnackBar(context);
        Loaders.successSnackBar(
          context,
          title: 'Image saved to gallery!',
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        Loaders.hideSnackBar(context);
        Loaders.errorSnackBar(
          context,
          title: 'Download Failed',
          message: e.toString(),
        );
      }
    }
  }
}

// Status Icon Widget
class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.schedule;
        color = context.colorScheme.onSurface.withValues(alpha:0.4);
        break;
      case MessageStatus.sent:
        iconData = Icons.check;
        color = context.colorScheme.onSurface.withValues(alpha:0.6);
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        color = context.colorScheme.onSurface.withValues(alpha:0.6);
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = context.colorScheme.primary;
        break;
    }

    return Icon(
      iconData,
      size: 14,
      color: color,
    );
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
  final bool isTyping;
  final bool isLoading;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSendMessage,
    required this.onPickImage,
    required this.isTyping,
    required this.isLoading,
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
              onPressed: widget.onPickImage,
              isLoading: widget.isLoading,
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
  final VoidCallback onPressed;
  final bool isLoading;

  const _AttachmentButton({
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
              Iconsax.gallery,
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
