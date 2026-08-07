import 'package:flutter/material.dart';
import 'package:tfm_app/core/theme/app_styles.dart';
import 'package:tfm_app/core/utils/date_formatter.dart';
import 'package:tfm_app/core/utils/l10n/app_localizations.dart';

class InferenceCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final AppLocalizations l10n;
  final String Function(int dateMs)? formatDate;

  const InferenceCard({
    super.key,
    required this.data,
    required this.l10n,
    this.formatDate,
  });

  String _translateVerdict(String v, AppLocalizations l10n) {
    if (v.contains('IRRIGATION AVOIDABLE:') || v.contains('Irrigation Avoidable')) {
      return l10n.verdictAvoidable;
    }
    if (v.contains('IRRIGATION NEEDED:') || v.contains('Irrigation Needed')) {
      return l10n.verdictNeeded;
    }
    if (v.startsWith('Verdict: ')) {
      final sub = v.substring(9);
      return 'Verdict: ${_translateVerdict(sub, l10n)}';
    }
    return v;
  }

  String _defaultFormatDate(int ms) {
    return AppDateFormatter.format(ms, showSeconds: true);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Container(
        margin: const EdgeInsets.only(top: AppStyles.spaceMD),
        padding: const EdgeInsets.all(AppStyles.spaceMD),
        decoration: AppStyles.aiRecommendationCard(Colors.grey),
        child: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.grey, size: 28),
            const SizedBox(width: AppStyles.spaceSM),
            Expanded(
              child: Text(
                l10n.homeAiNoData,
                style: AppStyles.sectionTitle.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final bool isRestricted = data!['isRestricted'] == true;
    if (isRestricted) {
      final startH = data!['agronomicStart'] as int? ?? 19;
      final endH = data!['agronomicEnd'] as int? ?? 9;
      return Container(
        margin: const EdgeInsets.only(top: AppStyles.spaceMD),
        padding: const EdgeInsets.all(AppStyles.spaceMD),
        decoration: AppStyles.aiRecommendationCard(AppStyles.warningAccent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: AppStyles.warningAccent, size: 28),
                const SizedBox(width: AppStyles.spaceSM),
                Expanded(
                  child: Text(
                    l10n.inferenceRestrictedTitle,
                    style: AppStyles.sectionTitle.copyWith(color: AppStyles.warningAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spaceSM),
            Text(
              l10n.inferenceRestrictedDesc(endH+1, startH-1, startH, endH),
              style: AppStyles.bodyText.copyWith(color: AppStyles.warningAccent),
            ),
          ],
        ),
      );
    }

    final bool hasMinHum = data!['minHumidity'] != null;
    if (!hasMinHum) {
      return Container(
        margin: const EdgeInsets.only(top: AppStyles.spaceMD),
        padding: const EdgeInsets.all(AppStyles.spaceMD),
        decoration: AppStyles.aiRecommendationCard(Colors.grey),
        child: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.grey, size: 28),
            const SizedBox(width: AppStyles.spaceSM),
            Expanded(
              child: Text(
                l10n.homeAiNoData,
                style: AppStyles.sectionTitle.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    final String? source = data!['source'] as String?;
    final verdict = data!['verdict'] as String? ?? 'UNKNOWN';
    final minHum = data!['minHumidity'] as double?;
    final minTs = data!['minDateMs'] as int?;
    final bool isUnrecommended = data!['isUnrecommended'] == true;
    final startH = data!['agronomicStart'] as int? ?? 19;
    final endH = data!['agronomicEnd'] as int? ?? 9;

    final emuMatch = RegExp(r'\[EMULATED: Date (.*?)\]').firstMatch(verdict);
    final bool isEmulated = emuMatch != null;
    final String emuText = isEmulated ? emuMatch.group(0)! : '';
    final String cleanVerdict = verdict.replaceAll(emuText, '').trim();

    final bool isIrrigate = cleanVerdict.toUpperCase().contains('NEEDED') || cleanVerdict.toUpperCase().contains('IRRIGATE:');
    final Color cardColor = isUnrecommended
        ? AppStyles.warningAccent
        : (isIrrigate ? AppStyles.waterActionAccent : AppStyles.successAccent);
    final IconData icon = isUnrecommended
        ? Icons.warning_amber_rounded
        : (isIrrigate ? Icons.water_drop : Icons.eco);

    int? effectiveMinTs = minTs;
    if (effectiveMinTs != null) {
      final now = DateTime.now();
      final dt = DateTime.fromMillisecondsSinceEpoch(effectiveMinTs);
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        effectiveMinTs += 86400000;
      }
    }

    final dateStr = effectiveMinTs != null
        ? (formatDate != null ? formatDate!(effectiveMinTs) : _defaultFormatDate(effectiveMinTs))
        : '';

    return Container(
      margin: const EdgeInsets.only(top: AppStyles.spaceMD),
      padding: const EdgeInsets.all(AppStyles.spaceMD),
      decoration: AppStyles.aiRecommendationCard(cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor, size: 28),
              const SizedBox(width: AppStyles.spaceSM),
              Expanded(
                child: Text(
                  isUnrecommended ? l10n.inferenceUnrecommendedTitle : l10n.inferenceRecommendedTitle,
                  style: AppStyles.sectionTitle.copyWith(color: cardColor),
                ),
              ),
              if (source != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppStyles.spaceSM, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: cardColor),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    l10n.inferenceInfoSource(source),
                    style: AppStyles.captionStatus.copyWith(color: cardColor),
                  ),
                ),
            ],
          ),
          if (isUnrecommended) ...[
            const SizedBox(height: AppStyles.spaceXS),
            Text(
              l10n.inferenceUnrecommendedWarning(startH, endH),
              style: AppStyles.captionStatus.copyWith(color: AppStyles.warningAccent, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: AppStyles.spaceSM),
          RichText(
            text: TextSpan(
              style: AppStyles.sectionTitle.copyWith(fontSize: 18, color: cardColor),
              children: [
                TextSpan(text: _translateVerdict(cleanVerdict, l10n)),
                if (isEmulated)
                  TextSpan(
                    text: '\n$emuText',
                    style: AppStyles.sectionTitle.copyWith(fontSize: 14, color: AppStyles.warningAccent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spaceSM),
          Divider(color: cardColor.withValues(alpha: 0.3)),
          const SizedBox(height: AppStyles.spaceSM),
          if (minHum != null && effectiveMinTs != null)
            Row(
              children: [
                Icon(Icons.show_chart, color: cardColor.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: AppStyles.spaceSM),
                Expanded(
                  child: Text(
                    l10n.homeAiMinHum((minHum * 100).toStringAsFixed(1), dateStr),
                    style: AppStyles.consoleBody.copyWith(color: cardColor),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
