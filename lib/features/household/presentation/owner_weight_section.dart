import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/weight_section.dart';

/// [WeightSection] for whoever this phone belongs to.
///
/// A thin wrapper so the screens that show weight do not each have to work out
/// whose it is. Until the phone has been claimed there is nobody to show, so it
/// takes up no room; the same is true when that person has weight tracking
/// switched off, which the section itself decides.
class OwnerWeightSection extends StatefulWidget {
  final HouseholdRepository? repository;

  const OwnerWeightSection({super.key, this.repository});

  @override
  State<OwnerWeightSection> createState() => _OwnerWeightSectionState();
}

class _OwnerWeightSectionState extends State<OwnerWeightSection> {
  HouseholdRepository get _repository =>
      widget.repository ?? locator<HouseholdRepository>();

  int? _owner;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final owner = await _repository.storedOwner();
    if (mounted) setState(() => _owner = owner);
  }

  @override
  Widget build(BuildContext context) {
    final owner = _owner;
    if (owner == null) return const SizedBox.shrink();
    return WeightSection(repository: _repository, personId: owner);
  }
}
