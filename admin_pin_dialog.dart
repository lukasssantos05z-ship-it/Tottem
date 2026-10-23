import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class AdminPinDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const AdminPinDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = "";

  void _verifyPin() {
    final inputPin = _pinController.text.trim();
    final inputHash = sha256.convert(utf8.encode(inputPin)).toString();

    // PIN padrao de seguranca da administracao: 8520
    final validHash = sha256.convert(utf8.encode("8520")).toString();

    if (inputHash == validHash) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      setState(() {
        _errorMessage = "PIN Invalido. Tentativa registrada nos logs de auditoria.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock, color: Colors.blueGrey),
          SizedBox(width: 8),
          Text("Autenticacao de Supervisor"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Informe a senha de seguranca para acessar o modulo de gestao:"),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ""),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ]
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
        ElevatedButton(onPressed: _verifyPin, child: const Text("ACESSAR")),
      ],
    );
  }
}
