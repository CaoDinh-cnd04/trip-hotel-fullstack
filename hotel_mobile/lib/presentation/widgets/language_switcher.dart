import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/language_service.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showAsDropdown;
  final bool showIcon;

  const LanguageSwitcher({
    super.key,
    this.showAsDropdown = false,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);

    if (showAsDropdown) {
      return _buildDropdown(l10n, languageService);
    } else {
      return _buildButton(l10n, languageService);
    }
  }

  Widget _buildButton(AppLocalizations l10n, LanguageService languageService) {
    return InkWell(
      onTap: () => languageService.toggleLanguage(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              const Icon(Icons.language, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              languageService.currentLanguageDisplayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    AppLocalizations l10n,
    LanguageService languageService,
  ) {
    return DropdownButton<String>(
      value: languageService.currentLanguageCode,
      underline: Container(),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: [
        DropdownMenuItem<String>(
          value: 'vi',
          child: Row(
            children: [
              const Text('🇻🇳'),
              const SizedBox(width: 8),
              Text(l10n.vietnamese),
            ],
          ),
        ),
        DropdownMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('🇺🇸'),
              const SizedBox(width: 8),
              Text(l10n.english),
            ],
          ),
        ),
      ],
      onChanged: (String? newLanguageCode) {
        if (newLanguageCode != null) {
          languageService.changeLanguage(newLanguageCode);
        }
      },
    );
  }
}

class LanguageSwitcherDialog extends StatelessWidget {
  const LanguageSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.language),
          const SizedBox(width: 8),
          Text(l10n.changeLanguage),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            context,
            'vi',
            '🇻🇳',
            l10n.vietnamese,
            languageService,
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context,
            'en',
            '🇺🇸',
            l10n.english,
            languageService,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String flag,
    String languageName,
    LanguageService languageService,
  ) {
    final isSelected = languageService.currentLanguageCode == languageCode;

    return InkWell(
      onTap: () {
        languageService.changeLanguage(languageCode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : null,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
