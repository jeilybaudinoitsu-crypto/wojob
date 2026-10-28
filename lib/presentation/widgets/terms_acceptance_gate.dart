import 'package:flutter/material.dart';

import 'package:wojob/domain/repositories/repositories.dart';
import 'package:wojob/presentation/widgets/terms_and_conditions_dialog.dart';

class TermsAcceptanceGate extends StatefulWidget {
  const TermsAcceptanceGate({
    super.key,
    required this.repository,
    required this.child,
  });

  final TermsAcceptanceRepository repository;
  final Widget child;

  @override
  State<TermsAcceptanceGate> createState() => _TermsAcceptanceGateState();
}

class _TermsAcceptanceGateState extends State<TermsAcceptanceGate> {
  late Future<bool> _acceptanceFuture;
  bool _accepted = false;
  bool _dialogScheduled = false;

  @override
  void initState() {
    super.initState();
    _acceptanceFuture = widget.repository.hasAcceptedTerms();
  }

  Future<void> _acceptTerms() async {
    await widget.repository.acceptTerms();
    if (mounted) setState(() => _accepted = true);
  }

  void _showTermsDialog() {
    if (_dialogScheduled || _accepted) return;
    _dialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _accepted) {
        _dialogScheduled = false;
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TermsAndConditionsDialog(onAccept: _acceptTerms),
      ).whenComplete(() {
        _dialogScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_accepted) return widget.child;

    return FutureBuilder<bool>(
      future: _acceptanceFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                      'No se pudo comprobar la aceptación de los términos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _acceptanceFuture = widget.repository
                              .hasAcceptedTerms();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.data == true) return widget.child;
        if (snapshot.connectionState == ConnectionState.done) {
          _showTermsDialog();
        }

        return const Scaffold(body: Center(child: Text('Cargando WoJob…')));
      },
    );
  }
}
