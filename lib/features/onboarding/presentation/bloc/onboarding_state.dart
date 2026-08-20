part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
}

class OnboardingInitialState extends OnboardingState {
  @override
  List<Object> get props => [];
}

class OnboardingLoadingState extends OnboardingState {
  @override
  List<Object?> get props => [];
}

class OnboardingLoadedState extends OnboardingState {
  @override
  List<Object?> get props => [];
}

/// The household already knew this person, so there is nothing to ask. The
/// screen leaves for the main app rather than drawing a form.
class OnboardingNotNeededState extends OnboardingState {
  @override
  List<Object?> get props => [];
}
