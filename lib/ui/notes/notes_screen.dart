import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/theme/rose_pine_theme.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/models.dart';
import '../../providers.dart';
import '../common/responsive_wrapper.dart';
import 'note_editor_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _selectedSubjectFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCloudSyncModal(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_sync_rounded, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gradient Cloud Backup',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Safely sync your notes across devices with Firebase',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (user != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.2),
                            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                            child: user.photoURL == null
                                ? Text(
                                    (user.displayName ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Student User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Connected',
                              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out'),
                            onPressed: () async {
                              await AuthService.instance.signOut();
                              setSheetState(() {});
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                            onPressed: _isSyncing
                                ? null
                                : () async {
                                    setSheetState(() => _isSyncing = true);
                                    final current = ref.read(notesNotifierProvider);
                                    final merged = await CloudSyncService.instance.syncAllNotes(current);
                                    await ref.read(notesNotifierProvider.notifier).saveNotes(merged);
                                    setSheetState(() => _isSyncing = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('✨ All notes synchronized with cloud!')),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Sign in with Google to enable automatic cloud backup for your notes, formula sheets, and study progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () async {
                                try {
                                  final cred = await AuthService.instance.signInWithGoogle();
                                  if (cred != null) {
                                    // Trigger initial sync
                                    final current = ref.read(notesNotifierProvider);
                                    final merged = await CloudSyncService.instance.syncAllNotes(current);
                                    await ref.read(notesNotifierProvider.notifier).saveNotes(merged);
                                    setSheetState(() {});
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Welcome, ${cred.user?.displayName ?? "Student"}!')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Google Sign-In notice: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final store = ref.watch(localStoreProvider);
    final notes = ref.watch(notesNotifierProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;

    final user = AuthService.instance.currentUser;

    // Filter by subject
    List<NoteItem> displayedNotes = _selectedSubjectFilter == 'All'
        ? notes.toList()
        : notes.where((n) => n.subjectId == _selectedSubjectFilter).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      displayedNotes = displayedNotes.where((n) {
        return n.title.toLowerCase().contains(_searchQuery) ||
            n.content.toLowerCase().contains(_searchQuery) ||
            n.subjectName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    final pinnedNotes = displayedNotes.where((n) => n.isPinned).toList();
    final otherNotes = displayedNotes.where((n) => !n.isPinned).toList();

    pinnedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    otherNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Cloud Sync button
          InkWell(
            onTap: () => _showCloudSyncModal(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: user != null
                    ? Colors.green.withValues(alpha: isDark ? 0.2 : 0.12)
                    : primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: user != null
                      ? Colors.green.withValues(alpha: 0.3)
                      : primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user != null ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    size: 16,
                    color: user != null ? Colors.green : primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user != null ? 'Cloud Synced' : 'Backup',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user != null ? Colors.green : primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(
                initialSubjectId: _selectedSubjectFilter,
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              // Clean Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes, formulas, topics...',
                      hintStyle: TextStyle(fontSize: 14, color: textSubtle),
                      prefixIcon: Icon(Icons.search_rounded, color: textSubtle, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Horizontal Subject Pills
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSubjectPill('All', 'All', notes.length),
                    for (final sub in store.subjects)
                      _buildSubjectPill(
                        sub.id,
                        '${sub.emoji} ${sub.name}',
                        notes.where((n) => n.subjectId == sub.id).length,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notes List / Grid
              Expanded(
                child: displayedNotes.isEmpty
                    ? _buildEmptyState(context)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        children: [
                          if (pinnedNotes.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.push_pin_rounded, size: 14, color: RosePineColors.dawnGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PINNED NOTES (${pinnedNotes.length})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      color: textSubtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final note in pinnedNotes) _buildNoteCard(note),
                            const SizedBox(height: 16),
                          ],
                          if (otherNotes.isNotEmpty && pinnedNotes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'OTHER NOTES (${otherNotes.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: textSubtle,
                                ),
                              ),
                            ),
                          for (final note in otherNotes) _buildNoteCard(note),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectPill(String id, String label, int count) {
    final isSelected = _selectedSubjectFilter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white24 : (isDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ],
        ),
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
        backgroundColor: isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface,
        selectedColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        onSelected: (_) {
          setState(() => _selectedSubjectFilter = id);
        },
      ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? RosePineColors.darkText : RosePineColors.dawnText;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;
    final cardBg = isDark ? RosePineColors.darkSurface : RosePineColors.dawnSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteEditorScreen(existingNote: note),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.subjectName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (note.isPinned)
                      const Icon(Icons.push_pin_rounded, size: 16, color: RosePineColors.dawnGold),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: textSubtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      _formatDate(note.updatedAt),
                      style: TextStyle(fontSize: 11, color: textSubtle.withValues(alpha: 0.8)),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 14,
                      color: Colors.green.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSubtle = isDark ? RosePineColors.darkSubtle : RosePineColors.dawnSubtle;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notes_rounded,
            size: 64,
            color: textSubtle.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isNotEmpty ? 'No notes matching "$_searchQuery"' : 'No notes yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSubtle),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with different keywords'
                : 'Tap + New Note to capture formulas and lecture insights',
            style: TextStyle(fontSize: 12.5, color: textSubtle.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
