/// The route behind "Add a food by hand".
///
/// It lives here rather than inline in main.dart for one reason: a route
/// written inside the routes map cannot be driven by a test, and this one was
/// wrong for weeks without anything noticing. Aidan typed a packet in on
/// 22 August, pressed Save, and was left sitting on the form he had just
/// filled with every box still full — so he read the save as having failed and
/// saved the same packet a second time. The two other routes that host this
/// same form have always closed it on a successful save. This one never did,
/// and no test could reach the difference.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
import 'package:opennutritracker/features/label_scan/presentation/take_it_to_today.dart';

/// The hand-typed packet form, as a whole screen.
///
/// The form itself is a section, not a page: it is a bare Column so the guided
/// capture flow can drop it into its own layout. A route has to supply what a
/// page needs — a Material ancestor for the fields, somewhere to scroll, and a
/// way back — or seven text fields land on nothing.
Widget addFoodByHandScreen(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Add a food by hand')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Builder(
            builder: (formContext) => ConfirmFoodScreen(
              logger: locator<HouseholdLogger>(),
              onSaved: (_) => Navigator.of(formContext).pop(),
              onPutOnDay: takeItToToday,
            ),
          ),
        ),
      ),
    );
