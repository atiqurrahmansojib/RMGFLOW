import 'package:flutter/material.dart';

/// "Tasks" and "Activity & notes" shortcuts for any record's detail/edit
/// screen (Doc 7 #83-86 — those modules are embedded per entity). The
/// screens are passed in as builders to keep this widget feature-agnostic.
class RecordLinks extends StatelessWidget {
  const RecordLinks({super.key, required this.tasks, required this.activity});

  final Widget Function() tasks;
  final Widget Function() activity;

  @override
  Widget build(BuildContext context) {
    void push(Widget Function() b) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => b()));
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.task_alt_rounded),
            title: const Text('Tasks'),
            subtitle: const Text('To-dos linked to this record'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => push(tasks),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Activity & notes'),
            subtitle: const Text('Calls, emails, meetings and notes'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => push(activity),
          ),
        ],
      ),
    );
  }
}
