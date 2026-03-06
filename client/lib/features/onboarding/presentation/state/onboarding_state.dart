sealed class OnboardingState {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class LocationSubmitted extends OnboardingState {
  const LocationSubmitted();
}

class ProfileSubmitted extends OnboardingState {
  const ProfileSubmitted();
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
}
