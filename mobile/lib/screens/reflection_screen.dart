import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/reflection_service.dart';
import '../models/reflection.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  double _adherence = 85;
  int _focus = 8;
  int _energy = 7;
  String _focusDesc = 'Laser focused, in the zone!';
  String _energyDesc = 'Good physical and mental drive.';
  final _successCtrl = TextEditingController();
  final _strugglesCtrl = TextEditingController();
  final _improvementsCtrl = TextEditingController();
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _saving = false;

  static const _focusTexts = {
    1: 'Very poor, constantly distracted.',
    2: 'Below average attention span.',
    3: 'Frequent scrolling and daydreaming.',
    4: 'Completed basic works but drifted.',
    5: 'Reasonable attention blocks.',
    6: 'Good productivity chunks.',
    7: 'Highly concentrated study sessions.',
    8: 'Superb momentum, minimal breaks.',
    9: 'Laser focused, in the zone!',
    10: 'Peak flow state achieved.',
  };

  static const _energyTexts = {
    1: 'Totally exhausted, heavy fatigue.',
    2: 'Drowsy and sluggish.',
    3: 'Low stamina, forcing work.',
    4: 'Moderate energy levels.',
    5: 'Neutral baseline drive.',
    6: 'Good energy, clear head.',
    7: 'Highly energetic and motivated.',
    8: 'Phenomenal stamina, vibrant focus.',
    9: 'Peak physical and mental drive.',
    10: 'Superhuman vitality.',
  };

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

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<ReflectionService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AetherColors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text('End of Day Metrics',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'Review Date'),
                  readOnly: true,
                  controller: TextEditingController(text: _selectedDate),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AetherColors.purple,
                            surface: Color(0xFF1A1530),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
                  },
                ),
                const SizedBox(height: 16),
                _slider('Plan Adherence (%)', _adherence.round(), AetherColors.purple, (v) => setState(() => _adherence = v), 0, 100),
                const SizedBox(height: 8),
                _slider('Focus Rating (1 - 10)', _focus, AetherColors.cyan, (v) => setState(() {
                  _focus = v.round();
                  _focusDesc = _focusTexts[_focus] ?? 'Consistent focused states.';
                }), 1, 10),
                Text(_focusDesc, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                const SizedBox(height: 8),
                _slider('Energy Level (1 - 10)', _energy, AetherColors.emerald, (v) => setState(() {
                  _energy = v.round();
                  _energyDesc = _energyTexts[_energy] ?? 'Excellent energy base.';
                }), 1, 10),
                Text(_energyDesc, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.book, color: AetherColors.emerald, size: 18),
                    const SizedBox(width: 8),
                    Text('Reflection Journal',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  ],
                ),
                const SizedBox(height: 16),
                _journalField('What went exceptionally well today?', 'Achievements, breakthroughs...', _successCtrl),
                const SizedBox(height: 12),
                _journalField('What got in your way?', 'Distractions, fatigue, blockers...', _strugglesCtrl),
                const SizedBox(height: 12),
                _journalField('What will you improve tomorrow?', 'Change timings, adjust study spots...', _improvementsCtrl),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveReflection,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 16),
                    label: const Text('Commit Daily Reflection'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: AetherColors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text('Historical Reflections Log',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  ],
                ),
                const SizedBox(height: 12),
                if (rs.reflections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No daily logs recorded yet. Reflect tonight!',
                        style: TextStyle(color: AetherColors.textMuted, fontSize: 13))),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.03)),
                      columns: const [
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                        DataColumn(label: Text('Adh.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                        DataColumn(label: Text('Focus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                        DataColumn(label: Text('Energy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                        DataColumn(label: Text('Highlights', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                        DataColumn(label: Text('Struggles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AetherColors.textBright))),
                      ],
                      rows: rs.reflections.map((r) => DataRow(
                        onSelectChanged: (_) => _showReflectionDetail(r),
                        cells: [
                        DataCell(Text(r.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AetherColors.textBright))),
                        DataCell(Row(children: [
                          Container(width: 40, height: 4, decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(2),
                          ), child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: r.adherenceScore / 100,
                            child: Container(decoration: BoxDecoration(
                              color: AetherColors.purple,
                              borderRadius: BorderRadius.circular(2),
                            )),
                          )),
                          const SizedBox(width: 4),
                          Text('${r.adherenceScore}%', style: const TextStyle(fontSize: 11, color: AetherColors.textBright)),
                        ])),
                        DataCell(Text('${r.focusScore}/10', style: const TextStyle(fontSize: 12, color: AetherColors.textBright))),
                        DataCell(Text('${r.energyScore}/10', style: const TextStyle(fontSize: 12, color: AetherColors.textBright))),
                        DataCell(SizedBox(
                          width: 120,
                          child: Text(r.notesSuccess.isNotEmpty ? r.notesSuccess : '—',
                              style: const TextStyle(fontSize: 11, color: AetherColors.textPrimary), overflow: TextOverflow.ellipsis),
                        )),
                        DataCell(SizedBox(
                          width: 120,
                          child: Text(r.notesStruggles.isNotEmpty ? r.notesStruggles : '—',
                              style: const TextStyle(fontSize: 11, color: AetherColors.textPrimary), overflow: TextOverflow.ellipsis),
                        )),
                      ])).toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _slider(String label, int value, Color color, ValueChanged<double> onChanged, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AetherColors.textPrimary)),
            Text('$value${label.contains('%') ? '%' : ''}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFamily: 'Outfit')),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.06),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round().toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _journalField(String label, String hint, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AetherColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  void _showReflectionDetail(Reflection r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1530),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reflection: ${r.date}',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCol(Icons.check_circle_outline, 'Adherence', '${r.adherenceScore}%', AetherColors.purple),
                _statCol(Icons.psychology, 'Focus', '${r.focusScore}/10', AetherColors.cyan),
                _statCol(Icons.bolt, 'Energy', '${r.energyScore}/10', AetherColors.emerald),
              ],
            ),
            const Divider(color: AetherColors.glassBorder, height: 24),
            _noteSection(Icons.star, 'What went well', r.notesSuccess, AetherColors.emerald),
            const SizedBox(height: 12),
            _noteSection(Icons.warning, 'Struggles & Distractions', r.notesStruggles, AetherColors.rose),
            const SizedBox(height: 12),
            _noteSection(Icons.lightbulb, 'Planned Improvements', r.notesImprovements, AetherColors.purple),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AetherColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _statCol(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, fontFamily: 'Outfit')),
        Text(label, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
      ],
    );
  }

  Widget _noteSection(IconData icon, String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content.isNotEmpty ? content : 'None recorded.',
              style: const TextStyle(fontSize: 12, color: AetherColors.textPrimary)),
        ),
      ],
    );
  }

  Future<void> _saveReflection() async {
    setState(() => _saving = true);
    final err = await context.read<ReflectionService>().saveReflection({
      'date': _selectedDate,
      'adherence_score': _adherence.round(),
      'focus_score': _focus,
      'energy_score': _energy,
      'notes_success': _successCtrl.text,
      'notes_struggles': _strugglesCtrl.text,
      'notes_improvements': _improvementsCtrl.text,
    });
    if (mounted) {
      setState(() => _saving = false);
      if (err == null) {
        _successCtrl.clear();
        _strugglesCtrl.clear();
        _improvementsCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reflection saved!'), duration: Duration(seconds: 2)),
        );
      }
    }
  }
}
