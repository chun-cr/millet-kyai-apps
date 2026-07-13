part of 'physique_question_page.dart';

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
    required this.title,
    required this.subtitle,
    required this.answeredCount,
    required this.skipLabel,
    required this.onSkip,
  });

  final String title;
  final String subtitle;
  final int answeredCount;
  final String skipLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: _kQuestionPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2C312E),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('scan_question_skip_button'),
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: _kQuestionPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(skipLabel),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF3A3028).withValues(alpha: 0.76),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.question_answer_outlined,
                label: l10n.scanQuestionAnsweredCount(answeredCount),
              ),
              _InfoChip(
                icon: Icons.bolt_outlined,
                label: l10n.scanQuestionOptionalTag,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.l10n,
    required this.question,
    required this.answeredCount,
    required this.selectedOptionValues,
    required this.isSubmitting,
    required this.hasSelection,
    required this.submissionErrorMessage,
    required this.onOptionSelected,
    required this.onSubmit,
  });

  final AppLocalizations l10n;
  final PhysiqueQuestionPayload? question;
  final int answeredCount;
  final Set<String> selectedOptionValues;
  final bool isSubmitting;
  final bool hasSelection;
  final String? submissionErrorMessage;
  final ValueChanged<String> onOptionSelected;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final resolvedQuestion = question;
    if (resolvedQuestion == null) {
      return _QuestionErrorView(
        title: l10n.scanQuestionLoadFailed,
        message: l10n.scanQuestionMissingQuestion,
        retryLabel: l10n.scanQuestionRetry,
        onRetry: onSubmit,
      );
    }

    final isLastQuestion =
        resolvedQuestion.currentIndex != null &&
        resolvedQuestion.totalCount != null &&
        resolvedQuestion.currentIndex! >= resolvedQuestion.totalCount!;
    final requiresExplicitSubmit = !resolvedQuestion.isSingleChoice;
    final resolvedSubmissionError = submissionErrorMessage?.trim() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: _kQuestionPrimary.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resolvedQuestion.currentIndex != null &&
                              resolvedQuestion.totalCount != null
                          ? l10n.scanQuestionProgressTitle(
                              resolvedQuestion.currentIndex!,
                              resolvedQuestion.totalCount!,
                            )
                          : l10n.scanQuestionSectionTitle,
                      style: const TextStyle(
                        color: _kQuestionPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Text(
                    l10n.scanQuestionAnsweredCount(answeredCount),
                    style: TextStyle(
                      color: const Color(0xFF3A3028).withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                resolvedQuestion.title,
                key: const ValueKey('scan_question_title'),
                style: const TextStyle(
                  color: Color(0xFF242924),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (resolvedQuestion.description.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  resolvedQuestion.description,
                  style: TextStyle(
                    color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ...resolvedQuestion.options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionOptionTile(
                    option: option,
                    selected: selectedOptionValues.contains(option.value),
                    allowsMultipleSelection:
                        resolvedQuestion.allowsMultipleSelection,
                    onTap: () => onOptionSelected(option.value),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: LinearProgressIndicator(
                    key: ValueKey('scan_question_submit_progress'),
                    minHeight: 4,
                    color: _kQuestionPrimaryLight,
                    backgroundColor: Color(0xFFE5EFE9),
                  ),
                ),
              if (resolvedSubmissionError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QuestionInlineError(message: resolvedSubmissionError),
                ),
              if (requiresExplicitSubmit)
                _PrimaryQuestionButton(
                  key: const ValueKey('scan_question_submit_button'),
                  label: isLastQuestion
                      ? l10n.scanQuestionSubmitAndReport
                      : l10n.scanQuestionNextButton,
                  enabled: hasSelection && !isSubmitting,
                  onTap: onSubmit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionInlineError extends StatelessWidget {
  const _QuestionInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB36A4C).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFFB36A4C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A4B38),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionOptionTile extends StatelessWidget {
  const _QuestionOptionTile({
    required this.option,
    required this.selected,
    required this.allowsMultipleSelection,
    required this.onTap,
  });

  final PhysiqueQuestionOption option;
  final bool selected;
  final bool allowsMultipleSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('scan_question_option_${option.value}'),
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? _kQuestionPrimary.withValues(alpha: 0.08)
              : const Color(0xFFF9F8F4),
          border: Border.all(
            color: selected
                ? _kQuestionPrimaryLight
                : _kQuestionPrimary.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            allowsMultipleSelection
                ? Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    activeColor: _kQuestionPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? _kQuestionPrimary : Colors.white,
                      border: Border.all(
                        color: selected
                            ? _kQuestionPrimary
                            : _kQuestionPrimary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: const Color(0xFF242924),
                      fontSize: 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (option.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      option.description,
                      style: TextStyle(
                        color: const Color(0xFF3A3028).withValues(alpha: 0.66),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionLoadingView extends StatelessWidget {
  const _QuestionLoadingView({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: _kQuestionPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF242924),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionErrorView extends StatelessWidget {
  const _QuestionErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _kQuestionPrimary.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFB36A4C),
                size: 32,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF242924),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3A3028).withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              _PrimaryQuestionButton(
                label: retryLabel,
                enabled: true,
                onTap: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionFooter extends StatelessWidget {
  const _QuestionFooter({required this.hint, required this.isLoading});

  final String hint;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kQuestionPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.sync_rounded : Icons.shield_outlined,
            size: 18,
            color: _kQuestionPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                color: const Color(0xFF3A3028).withValues(alpha: 0.74),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryQuestionButton extends StatelessWidget {
  const _PrimaryQuestionButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => unawaited(onTap()) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1D5E40),
                    _kQuestionPrimary,
                    _kQuestionPrimaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DDD8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _kQuestionPrimary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : const Color(0xFF9A9590),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _kQuestionPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kQuestionPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
