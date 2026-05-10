import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../repository/project_model.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mock data for projects
    final projects = [
      ProjectModel(
        id: 'P1',
        projectName: 'Green Valley Industrial Park',
        clientName: 'GV Infra',
        status: 'Active',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        description: 'Multi-warehouse industrial park construction.',
        progress: 0.65,
      ),
      ProjectModel(
        id: 'P2',
        projectName: 'Smart City Office Complex',
        clientName: 'Urban Corp',
        status: 'Planning',
        startDate: DateTime.now().add(const Duration(days: 15)),
        description: 'Premium office space with PEB structure.',
        progress: 0.1,
      ),
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Projects'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return _ProjectCard(project: project);
        },
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Navigate to sites of this project
          // For now, we just go to general site list
          context.push('${Routes.siteList}/site');
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.projectName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Client: ${project.clientName}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                  Text('${(project.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: project.progress,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => context.push('${Routes.siteList}/site'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('View Sites'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
