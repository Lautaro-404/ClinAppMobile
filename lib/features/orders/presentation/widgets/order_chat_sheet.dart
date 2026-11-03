import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:clinapp/core/l10n/app_strings.dart';
import 'package:clinapp/core/theme/app_colors.dart';
import 'package:clinapp/core/theme/app_palette.dart';
import 'package:clinapp/core/theme/app_spacing.dart';
import 'package:clinapp/core/theme/app_typography.dart';
import 'package:clinapp/core/utils/date_formatter.dart';
import 'package:clinapp/features/orders/data/supabase_orders_repository.dart';
import 'package:clinapp/features/orders/domain/orders_models.dart';
import 'package:clinapp/features/orders/domain/orders_repository.dart';
import 'package:clinapp/shared/widgets/glass_button.dart';
import 'package:clinapp/shared/widgets/glass_sheet.dart';
import 'package:clinapp/shared/widgets/glass_text_field.dart';

/// Provider reactivo de mensajes de chat por pedido con cancelación automática.
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((Ref ref, String orderId) {
      final OrdersRepository repository = ref.watch(ordersRepositoryProvider);
      return repository.watchChatMessages(orderId);
    });

/// Hoja modal de chat cliente–repartidor en tiempo real.
class OrderChatSheet extends ConsumerStatefulWidget {
  const OrderChatSheet({required this.order, super.key});

  final OrderSummary order;

  /// Muestra la hoja modal de chat.
  static Future<void> show(BuildContext context, OrderSummary order) {
    return GlassSheet.show<void>(
      context: context,
      child: OrderChatSheet(order: order),
    );
  }

  @override
  ConsumerState<OrderChatSheet> createState() => _OrderChatSheetState();
}

class _OrderChatSheetState extends ConsumerState<OrderChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      final OrdersRepository repository = ref.read(ordersRepositoryProvider);
      await repository.sendChatMessage(orderId: widget.order.id, content: text);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar el mensaje. Reintentá.'),
            backgroundColor: AppColors.danger,
          ),
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
    final AppPalette palette = context.palette;
    final AsyncValue<List<ChatMessage>> chatAsync = ref.watch(
      chatMessagesProvider(widget.order.id),
    );

    ref.listen(chatMessagesProvider(widget.order.id), (
      AsyncValue<List<ChatMessage>>? previous,
      AsyncValue<List<ChatMessage>> next,
    ) {
      _scrollToBottom();
    });

    return SizedBox(
      height: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    const Icon(
                      LucideIcons.messageSquare,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            AppStrings.ordersChatSheetTitle,
                            style: AppTypography.headlineMd.copyWith(
                              color: palette.textPrimary,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.order.courier != null
                                ? '${widget.order.courier!.name} · ${widget.order.merchantName}'
                                : '${widget.order.merchantName} · ${widget.order.shortCode}',
                            style: AppTypography.bodySm.copyWith(
                              color: palette.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassButton.icon(
                icon: LucideIcons.x,
                semanticLabel: AppStrings.actionClose,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: palette.rimMedium, height: 1),

          // Lista de mensajes
          Expanded(
            child: chatAsync.when(
              loading: () => const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
              error: (Object err, _) => Center(
                child: Text(
                  'Error al conectar al chat.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.danger),
                ),
              ),
              data: (List<ChatMessage> messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            LucideIcons.messageCircle,
                            size: 36,
                            color: palette.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Escribile al repartidor para coordinar la entrega.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage msg = messages[index];
                    return _ChatBubble(message: msg);
                  },
                );
              },
            ),
          ),

          Divider(color: palette.rimMedium, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Barra de entrada de texto
          Row(
            children: <Widget>[
              Expanded(
                child: GlassTextField(
                  controller: _textController,
                  hintText: AppStrings.ordersChatPlaceholder,
                  leadingIcon: LucideIcons.messageCircle,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GlassButton.primary(
                label: AppStrings.ordersSendMessage,
                leadingIcon: LucideIcons.send,
                semanticLabel: AppStrings.ordersSendMessage,
                isLoading: _isSending,
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.accent.withValues(alpha: 0.85)
              : palette.glassFill2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine ? AppColors.rimStrong : palette.rimMedium,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message.content,
              style: AppTypography.bodyMd.copyWith(
                color: isMine ? AppColors.onAccent : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormatter.time(message.createdAt),
              style: AppTypography.labelSm.copyWith(
                fontSize: 10,
                color: isMine
                    ? AppColors.onAccent.withValues(alpha: 0.75)
                    : palette.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
