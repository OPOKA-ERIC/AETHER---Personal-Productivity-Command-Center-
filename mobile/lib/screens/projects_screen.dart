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

  void _showCreateProject() {
    final ctrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New Project', style: GoogleFonts.outfit(color: AetherColors.textBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Project title'), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context.read<ProjectService>().createProject(ctrl.text.trim(), descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMilestone(Project project) {
    final ctrl = TextEditingController();
    final dateCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Milestone', style: GoogleFonts.outfit(color: AetherColors.textBright)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Milestone title'), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Due date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                context.read<ProjectService>().addMilestone(
                  project.id, ctrl.text.trim(),
                  dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectService = context.watch<ProjectService>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project Hub',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              ElevatedButton.icon(
                onPressed: _showCreateProject,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Project'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (projectService.projects.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.folder_open, color: AetherColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    const Text('No projects yet', style: TextStyle(color: AetherColors.textMuted)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _showCreateProject, child: const Text('Create your first project')),
                  ],
                ),
              ),
            )
          else
            ...projectService.projects.map((project) => _buildProjectCard(project)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final percent = project.completionPercent;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(project.title,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AetherColors.textBright)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AetherColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AetherColors.emerald)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AetherColors.rose, size: 18),
                onPressed: () => context.read<ProjectService>().deleteProject(project.id),
              ),
            ],
          ),
          if (project.description != null) ...[
            const SizedBox(height: 4),
            Text(project.description!, style: const TextStyle(color: AetherColors.textMuted, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: AetherColors.glassBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(AetherColors.purple),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: AetherColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...project.milestones.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.read<ProjectService>().toggleMilestone(m.id, !m.completed),
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: m.completed ? AetherColors.emerald : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: m.completed ? AetherColors.emerald : AetherColors.textMuted),
                    ),
                    child: m.completed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(m.title, style: TextStyle(
                    fontSize: 13, color: m.completed ? AetherColors.textMuted : AetherColors.textPrimary,
                    decoration: m.completed ? TextDecoration.lineThrough : null,
                  )),
                ),
                if (m.dueDate != null)
                  Text(m.dueDate!, style: const TextStyle(fontSize: 11, color: AetherColors.textMuted)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.read<ProjectService>().deleteMilestone(m.id),
                  child: const Icon(Icons.close, color: AetherColors.textMuted, size: 14),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAddMilestone(project),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Milestone', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
