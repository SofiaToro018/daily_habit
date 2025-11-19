import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/habit.dart';
import '../../providers/habit_providers.dart';

/// Widget para mostrar un hábito individual
class HabitCard extends ConsumerWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitCard({super.key, required this.habit, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox con animación
              GestureDetector(
                onTap: () async {
                  final repository = ref.read(habitRepositoryProvider);
                  await repository.toggleHabitCompletion(habit.id);
                  ref.invalidate(filteredHabitsProvider);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: habit.completed
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    color: habit.completed
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: habit.completed
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),

              const SizedBox(width: 16),

              // Información del hábito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        decoration: habit.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: habit.completed
                            ? Colors.grey
                            : theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    if (habit.description != null &&
                        habit.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (habit.streak > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.streak} día${habit.streak > 1 ? 's' : ''} de racha',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Botón de opciones
              IconButton(icon: const Icon(Icons.more_vert), onPressed: onTap),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}
