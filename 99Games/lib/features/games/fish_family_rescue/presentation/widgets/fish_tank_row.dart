import 'package:flutter/material.dart';
import '../../cubit/fish_family_cubit.dart';
import '../../cubit/fish_family_state.dart';
import 'fish_tank_widget.dart';

/// Responsive container displaying the aquarium tanks arranged into
/// balanced rows that fit phone and tablet screens without overflow.
class FishTankRow extends StatelessWidget {
  final FishFamilyState state;
  final FishFamilyCubit cubit;
  final Map<int, GlobalKey>? tankKeys;

  const FishTankRow({
    super.key,
    required this.state,
    required this.cubit,
    this.tankKeys,
  });

  @override
  Widget build(BuildContext context) {
    final tanks = state.tanks;
    final totalTanks = tanks.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 360 ? 8.0 : 12.0;

        // Partition tanks into rows based on total count
        List<Widget> rowWidgets;

        if (totalTanks <= 4) {
          // 1 to 4 tanks: single centered row
          rowWidgets = [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildTankList(context, tanks, spacing),
            ),
          ];
        } else {
          // 5 to 8 tanks: split into two rows
          final topRowCount = (totalTanks / 2).ceil();
          final topTanks = tanks.sublist(0, topRowCount);
          final bottomTanks = tanks.sublist(topRowCount);

          rowWidgets = [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildTankList(context, topTanks, spacing),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildTankList(context, bottomTanks, spacing),
            ),
          ];
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: rowWidgets,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTankList(
    BuildContext context,
    List<dynamic> tankSubset,
    double spacing,
  ) {
    final widgets = <Widget>[];

    for (int i = 0; i < tankSubset.length; i++) {
      final tank = tankSubset[i];
      final isSelected = state.selectedTankId == tank.id;
      final isShaking = state.shakingTankId == tank.id;

      if (i > 0) {
        widgets.add(SizedBox(width: spacing));
      }

      widgets.add(
        FishTankWidget(
          key: tankKeys?[tank.id],
          tank: tank,
          isSelected: isSelected,
          isShaking: isShaking,
          hiddenFishId: state.pendingMove?.fish.id,
          onTap: () => cubit.tapTank(tank.id),
        ),
      );
    }

    return widgets;
  }
}
