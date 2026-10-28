import 'package:flutter/material.dart';

import 'package:wojob/domain/repositories/repositories.dart';
import 'package:wojob/presentation/screens/onboarding_screen.dart';

class FirstRunGate extends StatefulWidget {
  const FirstRunGate({
    super.key,
    required this.repository,
    required this.child,
  });

  final FirstRunRepository repository;
  final Widget child;

  @override
  State<FirstRunGate> createState() => _FirstRunGateState();
}

class _FirstRunGateState extends State<FirstRunGate> {
  late Future<bool> _firstRunFuture;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _firstRunFuture = widget.repository.isFirstRun();
  }

  Future<void> _completeOnboarding() async {
    await widget.repository.completeFirstRun();
    if (mounted) setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) return widget.child;

    return FutureBuilder<bool>(
      future: _firstRunFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FirstRunError(
            onRetry: () {
              setState(() {
                _firstRunFuture = widget.repository.isFirstRun();
              });
            },
          );
        }

        if (snapshot.data == false) return widget.child;
        if (snapshot.connectionState == ConnectionState.done) {
          return OnboardingScreen(onComplete: _completeOnboarding);
        }

        return const Scaffold(body: Center(child: Text('Cargando WoJob…')));
      },
    );
  }
}

class _FirstRunError extends StatelessWidget {
  const _FirstRunError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              const Text(
                'No se pudo comprobar el estado de bienvenida.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    );
  }
}
