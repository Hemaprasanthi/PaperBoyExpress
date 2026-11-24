import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';

/// Issues reported by customers, delivery staff and admins.
class AdminIssuesTab extends StatelessWidget {
  const AdminIssuesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final issues = appState.issues;

    if (issues.isEmpty) {
      return const Center(child: Text('No issues reported.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final issue = issues[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(issue.subject,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: issue.resolved ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        issue.resolved ? 'Resolved' : 'Open',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: issue.resolved ? Colors.green[800] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${issue.reporterName} (${issue.reporterRole}) · ${formatDateTime(issue.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(issue.description),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => appState.setIssueResolved(issue.id, !issue.resolved),
                      icon: Icon(issue.resolved ? Icons.undo : Icons.check),
                      label: Text(issue.resolved ? 'Reopen' : 'Mark resolved'),
                    ),
                    TextButton.icon(
                      onPressed: () => appState.deleteIssue(issue.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
