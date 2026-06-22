import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import '../theme/aether_theme.dart';
import '../widgets/glass_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectService>().fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ps = context.watch<ProjectService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Long Term Projects & Milestones',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AetherColors.textBright)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateProjectModal(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Project', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ps.projects.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.account_tree, color: AetherColors.textMuted, size: 40),
                  const SizedBox(height: 12),
                  const Text('No active long-term projects',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                  const SizedBox(height: 4),
                  const Text('Break your learning goals into distinct progress milestones.',
                      style: TextStyle(fontSize: 13, color: AetherColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateProjectModal(context),
                    child: const Text('Create Your First Project'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          else
            ...ps.projects.map((p) => _projectCard(p, ps)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _projectCard(Project p, ProjectService ps) {
    final total = p.milestones.length;
    final completed = p.milestones.where((m) => m.completed).length;
    final percent = total > 0 ? (completed / total * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AetherColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AetherColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.title,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AetherColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AetherColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Text('active',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AetherColors.purple)),
              ),
            ],
          ),
          if (p.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.description, style: const TextStyle(fontSize: 13, color: AetherColors.textMuted)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Milestones Achieved', style: TextStyle(fontSize: 11, color: AetherColors.textMuted)),
              Text('$percent% ($completed/$total)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: percent >= 80 ? AetherColors.emerald : AetherColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.purple),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AetherColors.glassBorder),
          const SizedBox(height: 8),
          ...p.milestones.map((m) => _milestoneItem(m, ps)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showAddMilestoneModal(context, p.id),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AetherColors.glassBorder, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: AetherColors.textMuted, size: 14),
                  SizedBox(width: 6),
                  Text('Add Milestone Target',
                      style: TextStyle(fontSize: 12, color: AetherColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneItem(dynamic m, ProjectService ps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ps.toggleMilestone(m.id, !m.completed);
            },
            child: Icon(
              m.completed ? Icons.check_box : Icons.check_box_outline_blank,
              color: m.completed ? AetherColors.emerald : AetherColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(m.title,
                style: TextStyle(
                  fontSize: 13,
                  color: m.completed ? AetherColors.textMuted : AetherColors.textPrimary,
                  decoration: m.completed ? TextDecoration.lineThrough : null,
                )),
          ),
          if (m.dueDate != null) ...[
            const SizedBox(width: 8),
            Text(m.dueDate!, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted, fontFamily: 'monospace')),
          ],
          GestureDetector(
            onTap: () => ps.deleteMilestone(m.id),
            child: const Icon(Icons.delete_outline, color: AetherColors.textMuted, size: 16),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Long-Term Project',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Project Name')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Objective Description'), maxLines: 3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AetherColors.textMuted))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isNotEmpty) {
                        context.read<ProjectService>().createProject(titleCtrl.text.trim(), descCtrl.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Create Project'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMilestoneModal(BuildContext context, String projectId) {
    final titleCtrl = TextEditingController();
    String? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1530),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setInnerState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Milestone',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Milestone Title')),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(hintText: 'Due Date (YYYY-MM-DD)'),
                  onChanged: (v) => dueDate = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AetherColors.textMuted))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isNotEmpty) {
                          context.read<ProjectService>().createMilestone(projectId, titleCtrl.text.trim(), dueDate);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Add Milestone'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
