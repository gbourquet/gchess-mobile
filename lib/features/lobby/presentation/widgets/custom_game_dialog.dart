import 'package:flutter/material.dart';

class CustomGameDialog extends StatefulWidget {
  final Function(int totalTimeMinutes, int incrementSeconds) onStartGame;

  const CustomGameDialog({
    super.key,
    required this.onStartGame,
  });

  @override
  State<CustomGameDialog> createState() => _CustomGameDialogState();
}

class _CustomGameDialogState extends State<CustomGameDialog> {
  final _timeController = TextEditingController(text: '10');
  final _incrementController = TextEditingController(text: '0');
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _timeController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  void _handleStart() {
    setState(() => _errorMessage = null);
    
    if (_formKey.currentState!.validate()) {
      final time = int.tryParse(_timeController.text);
      final increment = int.tryParse(_incrementController.text);
      
      if (time == null || increment == null) {
        setState(() => _errorMessage = 'Invalid input');
        return;
      }
      
      if (time < 1) {
        setState(() => _errorMessage = 'Time must be at least 1 minute');
        return;
      }
      
      if (increment < 0) {
        setState(() => _errorMessage = 'Increment must be 0 or more');
        return;
      }
      
      Navigator.of(context).pop();
      widget.onStartGame(time, increment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Game'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _timeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time (minutes)',
                border: OutlineInputBorder(),
                hintText: '10',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter time';
                }
                final time = int.tryParse(value);
                if (time == null) {
                  return 'Invalid number';
                }
                if (time < 1) {
                  return 'Must be at least 1 minute';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _incrementController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Increment (seconds)',
                border: OutlineInputBorder(),
                hintText: '0',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter increment';
                }
                final increment = int.tryParse(value);
                if (increment == null) {
                  return 'Invalid number';
                }
                if (increment < 0) {
                  return 'Must be 0 or more';
                }
                return null;
              },
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleStart,
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}
