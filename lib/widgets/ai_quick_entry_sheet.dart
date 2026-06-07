import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/record.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../services/ai_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AiQuickEntrySheet extends StatefulWidget {
  const AiQuickEntrySheet({Key? key}) : super(key: key);

  @override
  State<AiQuickEntrySheet> createState() => _AiQuickEntrySheetState();
}

enum AiEntryStep { input, loading, confirm }

class _AiQuickEntrySheetState extends State<AiQuickEntrySheet> {
  AiEntryStep _currentStep = AiEntryStep.input;
  final TextEditingController _promptController = TextEditingController();
  String? _errorMessage;

  // Speech-to-Text Fields
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // Parsed Transaction Details
  String _type = 'expense';
  double _amount = 0.0;
  String _note = '';
  DateTime _dateTime = DateTime.now();
  String? _selectedAccountId;
  String? _selectedCategoryId;

  // For Transfers
  String? _fromAccountId;
  String? _toAccountId;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speechToText.stop();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final hasSpeech = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint("Speech status: $status");
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (errorVal) {
          debugPrint("Speech error: $errorVal");
          setState(() {
            _isListening = false;
            _errorMessage = "Speech Recognition Error: ${errorVal.errorMsg}";
          });
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = hasSpeech;
        });
        if (hasSpeech) {
          _startListening();
        }
      }
    } catch (e) {
      debugPrint("Speech initialization exception: $e");
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _errorMessage = null;
    });
    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _promptController.text = result.recognizedWords;
          });
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _processPrompt(context);
          }
        }
      },
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processPrompt(BuildContext context) async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final walletProv = Provider.of<WalletProvider>(context, listen: false);
    final apiKey = authProv.geminiApiKey;
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) return;

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'API Key is missing. Please configure it in Settings.';
      });
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }

    setState(() {
      _currentStep = AiEntryStep.loading;
      _errorMessage = null;
    });

    final accountNames = walletProv.accounts.map((a) => a.name).toList();
    final categoryNames = walletProv.categories.map((c) => c.name).toList();

    try {
      final result = await AiService.parseTransaction(
        apiKey: apiKey,
        prompt: prompt,
        currentDateTime: DateTime.now(),
        accounts: accountNames,
        categories: categoryNames,
      );

      if (result == null) {
        setState(() {
          _currentStep = AiEntryStep.input;
          _errorMessage = 'Failed to analyze text. Please try again with different phrasing.';
        });
        return;
      }

      // Populate details from Gemini's response
      _amount = (result['amount'] ?? 0.0) is int
          ? (result['amount'] as int).toDouble()
          : (result['amount'] ?? 0.0);
      _type = result['type'] ?? 'expense';
      _note = result['note'] ?? '';
      
      final parsedDate = result['dateTime'] != null
          ? DateTime.tryParse(result['dateTime'])
          : null;
      _dateTime = parsedDate ?? DateTime.now();

      // Find matching account
      final accName = result['accountName'] as String?;
      Account? matchedAcc;
      if (accName != null) {
        for (var acc in walletProv.accounts) {
          if (acc.name.toLowerCase() == accName.toLowerCase()) {
            matchedAcc = acc;
            break;
          }
        }
      }
      _selectedAccountId = matchedAcc?.id ?? (walletProv.accounts.isNotEmpty ? walletProv.accounts.first.id : null);

      // Find matching category
      final catName = result['categoryName'] as String?;
      Category? matchedCat;
      if (catName != null) {
        for (var cat in walletProv.categories) {
          if (cat.name.toLowerCase() == catName.toLowerCase()) {
            matchedCat = cat;
            break;
          }
        }
      }
      _selectedCategoryId = matchedCat?.id;

      // Handle Transfer accounts
      if (_type == 'transfer') {
        final fromName = result['fromAccountName'] as String?;
        final toName = result['toAccountName'] as String?;
        Account? matchedFrom;
        Account? matchedTo;

        for (var acc in walletProv.accounts) {
          if (fromName != null && acc.name.toLowerCase() == fromName.toLowerCase()) {
            matchedFrom = acc;
          }
          if (toName != null && acc.name.toLowerCase() == toName.toLowerCase()) {
            matchedTo = acc;
          }
        }

        _fromAccountId = matchedFrom?.id ?? _selectedAccountId;
        _toAccountId = matchedTo?.id ?? (walletProv.accounts.length > 1 ? walletProv.accounts[1].id : null);
      }

      setState(() {
        _currentStep = AiEntryStep.confirm;
      });
    } catch (e) {
      setState(() {
        _currentStep = AiEntryStep.input;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  void _submitTransaction(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context, listen: false);

    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than zero.')),
      );
      return;
    }

    if (_type != 'transfer' && _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid account.')),
      );
      return;
    }

    if (_type == 'transfer' && (_fromAccountId == null || _toAccountId == null || _fromAccountId == _toAccountId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select two distinct accounts for transfer.')),
      );
      return;
    }

    final newRecord = Record(
      id: _uuid.v4(),
      type: _type,
      amount: _amount,
      currency: 'INR',
      accountId: _type == 'transfer' ? _fromAccountId! : _selectedAccountId!,
      fromAccountId: _type == 'transfer' ? _fromAccountId : null,
      toAccountId: _type == 'transfer' ? _toAccountId : null,
      categoryId: _type == 'transfer' ? null : _selectedCategoryId,
      note: _note,
      dateTime: _dateTime,
      createdAt: DateTime.now(),
    );

    walletProv.addRecord(newRecord);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction successfully recorded!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162A35) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStepContent(walletProv, theme, isDark),
      ),
    );
  }

  Widget _buildStepContent(WalletProvider walletProv, ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case AiEntryStep.input:
        return _buildInputStep(theme, isDark);
      case AiEntryStep.loading:
        return _buildLoadingStep(theme);
      case AiEntryStep.confirm:
        return _buildConfirmStep(walletProv, theme, isDark);
    }
  }

  Widget _buildInputStep(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Gemini AI Entry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF263238),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Describe your transaction in simple words. For example:\n'
          '• "spent 120 on coffee just now"\n'
          '• "salary credit of 50000 yesterday at 10 AM"\n'
          '• "transferred 1000 from Bank to Cash"',
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _promptController,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What transaction would you like to record?',
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.done,
          onChanged: (val) {
            if (_isListening) {
              _stopListening();
            }
          },
          onSubmitted: (_) => _processPrompt(context),
        ),
        if (_isListening) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Listening to your voice...',
                style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.bolt),
                  label: const Text('Analyze with AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () => _processPrompt(context),
                ),
              ),
            ),
            if (_speechEnabled) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withOpacity(0.12) : theme.colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening ? Colors.red : theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStep(ThemeData theme) {
    return Column(
      key: const ValueKey('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Gemini is parsing your transaction...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Reading amounts, categories, and matching accounts',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildConfirmStep(WalletProvider walletProv, ThemeData theme, bool isDark) {
    // Resolve colors for aesthetics
    final Color headerColor = _type == 'expense'
        ? Colors.red.shade400
        : (_type == 'income' ? Colors.green.shade400 : Colors.blue.shade400);

    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Confirm AI Entry',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF263238),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        const SizedBox(height: 16),

        // Type badge and parsed preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: headerColor.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Text(
                _type.toUpperCase(),
                style: TextStyle(
                  color: headerColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'INR ${_amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (_note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _note,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Transaction Details Forms
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _amount.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                onChanged: (val) {
                  setState(() {
                    _amount = double.tryParse(val) ?? 0.0;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: _note,
          decoration: const InputDecoration(labelText: 'Note / Description'),
          onChanged: (val) {
            _note = val;
          },
        ),
        const SizedBox(height: 12),

        if (_type != 'transfer') ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: walletProv.accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedAccountId = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('Uncategorized')),
                    ...walletProv.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fromAccountId,
                  decoration: const InputDecoration(labelText: 'From Account'),
                  items: walletProv.accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _fromAccountId = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: const InputDecoration(labelText: 'To Account'),
                  items: walletProv.accounts.map((a) {
                    return DropdownMenuItem(value: a.id, child: Text(a.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _toAccountId = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),
        // Date Time display & Picker
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _dateTime,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              if (!mounted) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_dateTime),
              );
              if (pickedTime != null) {
                setState(() {
                  _dateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E333F) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Date & Time',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_dateTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() {
                    _currentStep = AiEntryStep.input;
                    _promptController.clear();
                  });
                  if (_speechEnabled) {
                    _startListening();
                  }
                },
                child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _submitTransaction(context),
                child: const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
