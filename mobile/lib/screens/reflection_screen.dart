import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reflection.dart';
import '../services/reflection_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  DateTime _selectedDate = DateTime.now();
  double _adherence = 70;
  double _focus = 6;
  double _energy = 6;
  final _successCtrl = TextEditingController();
  final _strugglesCtrl = TextEditingController();
  final _improvementsCtrl = TextEditingController();
  bool _saving = false;

  String _focusLabel(int v) {
    const labels = {1: 'Scattered', 3: 'Distracted', 5: 'Moderate', 7: 'Focused', 10: 'Hyperfocused'};
    return labels.entries.firstWhere((e) => v <= e.key, orElse: () => const MapEntry(10, 'Hyperfocused')).value;
  }

  String _energyLabel(int v) {
    const labels = {1: 'Exhausted', 3: 'Tired', 5: 'Steady', 7: 'Energetic', 10: 'Buzzing'};
    return labels.entries.firstWhere((e) => v <= e.key, orElse: () => const MapEntry(10, 'Buzzing')).value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReflectionService>().fetchReflections();
    });
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _strugglesCtrl.dispose();
    _improvementsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final service = context.read<ReflectionService>();
    final ref = Reflection(
      id: '',
      userId: '',
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      adherenceScore: _adherence.toInt(),
      focusScore: _focus.toInt(),
      energyScore: _energy.toInt(),
      notesSuccess: _successCtrl.text.trim().isEmpty ? null : _successCtrl.text.trim(),
      notesStruggles: _strugglesCtrl.text.trim().isEmpty ? null : _strugglesCtrl.text.trim(),
      notesImprovements: _improvementsCtrl.text.trim().isEmpty ? null : _improvementsCtrl.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    await service.saveReflection(ref);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reflection saved!'), backgroundColor: AetherColors.emerald),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refService = context.watch<ReflectionService>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Reflection',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _slider('Adherence', _adherence, 100, AetherColors.emerald, '${_adherence.toInt()}%'),
                const SizedBox(height: 16),
                _slider('Focus', _focus, 10, AetherColors.purple, '${_focus.toInt()} - ${_focusLabel(_focus.toInt())}'),
                const SizedBox(height: 16),
                _slider('Energy', _energy, 10, AetherColors.cyan, '${_energy.toInt()} - ${_energyLabel(_energy.toInt())}'),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Text('What went well?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AetherColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(controller: _successCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Your wins today...')),
                const SizedBox(height: 12),
                Text('What got in your way?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AetherColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(controller: _strugglesCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Any obstacles...')),
                const SizedBox(height: 12),
                Text('Adjustment for tomorrow?', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AetherColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(controller: _improvementsCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'One thing to improve...')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Commit Daily Reflection'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
          const SizedBox(height: 12),
          if (refService.reflections.isEmpty)
            const Text('No reflections yet', style: TextStyle(color: AetherColors.textMuted))
          else
            ...refService.reflections.take(10).map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AetherColors.glass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AetherColors.glassBorder),
              ),
              child: InkWell(
                onTap: () => _showReflectionDetail(r),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(r.date, style: const TextStyle(color: AetherColors.textPrimary, fontSize: 13))),
                    Expanded(child: _miniBar(r.adherenceScore)),
                    Expanded(child: Text('${r.focusScore}', textAlign: TextAlign.center,
                        style: TextStyle(color: AetherColors.purple, fontSize: 13))),
                    Expanded(child: Text('${r.energyScore}', textAlign: TextAlign.center,
                        style: TextStyle(color: AetherColors.cyan, fontSize: 13))),
                    if (r.notesSuccess != null)
                      const Icon(Icons.short_text, color: AetherColors.textMuted, size: 14),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double max, Color color, String display) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AetherColors.textPrimary)),
            const Spacer(),
            Text(display, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: (v) {
              setState(() {
                if (label == 'Adherence') { _adherence = v; }
                else if (label == 'Focus') { _focus = v; }
                else { _energy = v; }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _miniBar(int value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            Flexible(
              flex: value,
              child: Container(color: AetherColors.emerald),
            ),
            Flexible(
              flex: 100 - value,
              child: Container(color: AetherColors.glassBorder),
            ),
          ],
        ),
      ),
    );
  }

  void _showReflectionDetail(Reflection r) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.date, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
            const SizedBox(height: 16),
            _detailRow('Adherence', '${r.adherenceScore}%', AetherColors.emerald),
            _detailRow('Focus', '${r.focusScore}/10', AetherColors.purple),
            _detailRow('Energy', '${r.energyScore}/10', AetherColors.cyan),
            if (r.notesSuccess != null) ...[const SizedBox(height: 12), Text('Went well:', style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)), Text(r.notesSuccess!)],
            if (r.notesStruggles != null) ...[const SizedBox(height: 12), Text('Struggles:', style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)), Text(r.notesStruggles!)],
            if (r.notesImprovements != null) ...[const SizedBox(height: 12), Text('Improvements:', style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)), Text(r.notesImprovements!)],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: AetherColors.textMuted, fontSize: 14)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
