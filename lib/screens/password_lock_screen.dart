import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salary_provider.dart';

class PasswordLockScreen extends StatefulWidget {
  final bool isSetupMode;
  final VoidCallback? onSetupSuccess;

  const PasswordLockScreen({
    super.key,
    this.isSetupMode = false,
    this.onSetupSuccess,
  });

  @override
  State<PasswordLockScreen> createState() => _PasswordLockScreenState();
}

class _PasswordLockScreenState extends State<PasswordLockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureText = true;
  bool _obscureConfirmText = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<SalaryProvider>(context, listen: false);

    final pass = _passController.text;
    final confirm = _confirmPassController.text;

    if (widget.isSetupMode) {
      if (pass != confirm) {
        setState(() {
          _errorMessage = 'Les mots de passe ne correspondent pas';
        });
        return;
      }
      await provider.enablePasswordSecurity(pass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe configuré avec succès !')),
        );
        if (widget.onSetupSuccess != null) {
          widget.onSetupSuccess!();
        } else {
          Navigator.pop(context);
        }
      }
    } else {
      // Unlock Mode
      final success = provider.verifyAndUnlock(pass);
      if (!success) {
        setState(() {
          _errorMessage = 'Mot de passe incorrect';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Header & Lock Icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Color(0xFF10B981),
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.isSetupMode
                      ? 'Créer un mot de passe'
                      : 'Application Verrouillée',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isSetupMode
                      ? 'Entrez un mot de passe sécurisé pour protéger vos données'
                      : 'Veuillez saisir votre mot de passe pour déverrouiller',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Visualisez. Économisez. Évoluez.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Main Password Field
                TextFormField(
                  controller: _passController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: widget.isSetupMode ? 'Nouveau mot de passe' : 'Mot de passe',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Veuillez entrer un mot de passe';
                    if (val.length < 4) return 'Le mot de passe doit contenir au moins 4 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field (if setup mode)
                if (widget.isSetupMode) ...[
                  TextFormField(
                    controller: _confirmPassController,
                    obscureText: _obscureConfirmText,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmText ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmText = !_obscureConfirmText),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Veuillez confirmer le mot de passe';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_errorMessage.isNotEmpty) ...[
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _submit,
                    child: Text(
                      widget.isSetupMode ? 'Enregistrer le mot de passe' : 'Déverrouiller',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
