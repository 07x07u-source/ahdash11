import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/guest_capability_policy.dart';
import 'auth_controller.dart';

final capabilityPolicyProvider = Provider<GuestCapabilityPolicy>(
  (ref) =>
      GuestCapabilityPolicy(ref.watch(authControllerProvider).asData?.value),
);
