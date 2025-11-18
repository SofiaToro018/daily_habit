import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/habit.dart';
import '../../providers/habit_providers.dart';
import '../widgets/habit_card.dart';

/// Pantalla principal de la aplicación
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(habitFilterProvider);
    final habitsAsync = ref.watch(filteredHabitsProvider);
    final syncState = ref.watch(syncStateProvider);
    final pendingOpsAsync = ref.watch(pendingOperationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hábitos'),
        actions: [
          // Indicador de sincronización
          pendingOpsAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Chip(
                        label: Text('$count pendiente${count > 1 ? 's' : ''}'),
                        avatar: const Icon(Icons.cloud_upload, size: 16),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Botón de sincronización
          IconButton(
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: syncState.isSyncing
                ? null
                : () async {
                    await ref.read(syncStateProvider.notifier).syncNow();
                    ref.invalidate(filteredHabitsProvider);
                    ref.invalidate(pendingOperationsCountProvider);
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensaje de sincronización
          if (syncState.message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: syncState.hasError
                  ? theme.colorScheme.error.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    syncState.hasError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: syncState.hasError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncState.message!,
                      style: TextStyle(
                        color: syncState.hasError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    onPressed: () {
                      ref.read(syncStateProvider.notifier).clearMessage();
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(),

          // Filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todos',
                    isSelected: filter == HabitFilter.all,
                    onTap: () => ref
                        .read(habitFilterProvider.notifier)
                        .setFilter(HabitFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendientes',
                    isSelected: filter == HabitFilter.pending,
                    onTap: () => ref
                        .read(habitFilterProvider.notifier)
                        .setFilter(HabitFilter.pending),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completados',
                    isSelected: filter == HabitFilter.completed,
                    onTap: () => ref
                        .read(habitFilterProvider.notifier)
                        .setFilter(HabitFilter.completed),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Rachas 🔥',
                    isSelected: filter == HabitFilter.streak,
                    onTap: () => ref
                        .read(habitFilterProvider.notifier)
                        .setFilter(HabitFilter.streak),
                  ),
                ],
              ),
            ),
          ),

          // Lista de hábitos
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final repository = ref.read(habitRepositoryProvider);
                await repository.getAllHabits(forceRefresh: true);
                ref.invalidate(filteredHabitsProvider);
              },
              child: habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay hábitos aún',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu primer hábito para comenzar',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return HabitCard(
                        habit: habit,
                        onTap: () => _showHabitOptions(context, habit),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar hábitos',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateHabitDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Hábito'),
      ).animate().scale(delay: 300.ms),
    );
  }

  void _showCreateHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Hábito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Hacer ejercicio',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Ej: 30 minutos de cardio',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El título es obligatorio')),
                );
                return;
              }

              final repository = ref.read(habitRepositoryProvider);
              await repository.createHabit(
                titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(filteredHabitsProvider);
                ref.invalidate(pendingOperationsCountProvider);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showHabitOptions(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _showEditHabitDialog(context, habit);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final repository = ref.read(habitRepositoryProvider);
                await repository.deleteHabit(habit.id);
                ref.invalidate(filteredHabitsProvider);
                ref.invalidate(pendingOperationsCountProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHabitDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController(text: habit.title);
    final descriptionController = TextEditingController(
      text: habit.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Hábito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El título es obligatorio')),
                );
                return;
              }

              final repository = ref.read(habitRepositoryProvider);
              final updatedHabit = habit.copyWith(
                title: titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
              await repository.updateHabit(updatedHabit);

              if (context.mounted) {
                Navigator.pop(context);
                ref.invalidate(filteredHabitsProvider);
                ref.invalidate(pendingOperationsCountProvider);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
