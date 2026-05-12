import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

import '../core/models/currency_transaction.dart';
import '../core/models/wallet.dart';
import '../core/dao/currency_transaction_dao.dart';
import '../core/dao/wallet_dao.dart';

class NewCurrencyPurchaseScreen extends StatefulWidget {
  final int userId;
  final CurrencyTransaction? transaction;

  const NewCurrencyPurchaseScreen({
    super.key,
    required this.userId,
    this.transaction,
  });

  @override
  State<NewCurrencyPurchaseScreen> createState() => _NewCurrencyPurchaseScreenState();
}

class _NewCurrencyPurchaseScreenState extends State<NewCurrencyPurchaseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalBRLController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCurrency = 'Euro';
  final List<String> _currencies = ['Euro', 'Dólar', 'Libra', 'Nova'];
  
  String _selectedOrigin = 'Wise';
  final List<String> _origins = ['Wise', 'Revolut', 'Picnic', 'Papel', 'Nova'];
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateVET);
    _totalBRLController.addListener(_updateVET);
    
    _loadPersistedOptions();

    if (widget.transaction != null) {
      final data = widget.transaction!;
      _amountController.text = data.amount.toString();
      _totalBRLController.text = data.amountBrl.toString();
      _selectedCurrency = data.currency;
      
      String origin = data.source;
      if (!_origins.contains(origin)) {
        _origins.insert(_origins.length - 1, origin);
      }
      _selectedOrigin = origin;
      
      _descriptionController.text = data.description ?? '';
      
      try {
        final dateParts = data.date.split('/');
        _selectedDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  Future<void> _loadPersistedOptions() async {
    final transactions = await CurrencyTransactionDAO().getTransactionsByUser(widget.userId);
    if (mounted) {
      setState(() {
        for (var t in transactions) {
          if (!_currencies.contains(t.currency)) _currencies.insert(_currencies.length - 1, t.currency);
          if (!_origins.contains(t.source)) _origins.insert(_origins.length - 1, t.source);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _totalBRLController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateVET() {
    setState(() {}); // Trigger rebuild to update the VET text
  }

  String get _calculatedVET {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final totalBRL = double.tryParse(_totalBRLController.text.replaceAll(',', '.')) ?? 0;
    if (amount > 0 && totalBRL > 0) {
      return "VET: R\$ ${(totalBRL / amount).toStringAsFixed(2).replaceAll('.', ',')}";
    }
    return "VET: R\$ 0,00";
  }

  void _showNewOptionDialog({required bool isCurrency}) {
    final TextEditingController newOptionController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(isCurrency ? "Nova Moeda" : "Nova Origem", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: newOptionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isCurrency ? "Ex: Peso Argentino" : "Ex: Nomad",
            hintStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.silverBorder)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.moneyGreen)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (isCurrency) {
                  _selectedCurrency = _currencies.first;
                } else {
                  _selectedOrigin = _origins.first;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              if (newOptionController.text.trim().isNotEmpty) {
                final newValue = newOptionController.text.trim();
                setState(() {
                  if (isCurrency) {
                    _currencies.insert(_currencies.length - 1, newValue);
                    _selectedCurrency = newValue;
                  } else {
                    _origins.insert(_origins.length - 1, newValue);
                    _selectedOrigin = newValue;
                  }
                });
              } else {
                setState(() {
                  if (isCurrency) {
                    _selectedCurrency = _currencies.first;
                  } else {
                    _selectedOrigin = _origins.first;
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text("Adicionar", style: TextStyle(color: AppColors.moneyGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint, 
    TextEditingController? controller, 
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines == 1 ? 45 : null,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.silverBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: maxLines == 1 ? 12 : 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction != null ? "editar saldo" : "adicionar saldo",
          style: const TextStyle(color: AppColors.offWhite, fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
        ),
        centerTitle: true,
        toolbarHeight: 80,
        actions: widget.transaction != null ? [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: const Text("Excluir Saldo", style: TextStyle(color: Colors.white)),
                  content: const Text("Tem certeza que deseja excluir esta compra?", style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white))),
                    TextButton(
                      onPressed: () async {
                        final transaction = widget.transaction!;
                        await CurrencyTransactionDAO().deleteTransaction(transaction.id!);
                        
                        final walletDao = WalletDAO();
                        final wallet = await walletDao.getWallet(transaction.userId, transaction.currency);
                        if (wallet != null) {
                          final newBalance = wallet.balance - transaction.amount;
                          if (newBalance <= 0) {
                            await walletDao.deleteWallet(transaction.userId, transaction.currency);
                          } else {
                            double totalBrlAntigo = wallet.balance * wallet.averageVet;
                            double novoTotalBrl = totalBrlAntigo - transaction.amountBrl;
                            double newVet = novoTotalBrl / newBalance;

                            await walletDao.updateWallet(Wallet(
                              userId: transaction.userId,
                              currency: transaction.currency,
                              balance: newBalance,
                              averageVet: newVet,
                            ));
                          }
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Valor e Moeda
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    hint: "Valor", 
                    controller: _amountController, 
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.silverBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        dropdownColor: AppColors.darkBackground,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue == 'Nova') {
                            _showNewOptionDialog(isCurrency: true);
                          } else if (newValue != null) {
                            setState(() => _selectedCurrency = newValue);
                          }
                        },
                        items: _currencies.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Valor pago em reais
            _buildTextField(
              hint: "Valor pago em reais", 
              controller: _totalBRLController, 
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            
            // Texto do VET
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _calculatedVET,
                style: const TextStyle(color: AppColors.moneyGreen, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Origem
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.silverBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedOrigin,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  dropdownColor: AppColors.darkBackground,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue == 'Nova') {
                      _showNewOptionDialog(isCurrency: false);
                    } else if (newValue != null) {
                      setState(() => _selectedOrigin = newValue);
                    }
                  },
                  items: _origins.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data
            Container(
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.silverBorder),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.moneyGreen,
                            surface: AppColors.darkBackground,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                label: Text(
                  "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}", 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w300
                  )
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Descrição
            _buildTextField(
              hint: "Descrição (opcional)", 
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: 48),

            // Botão Salvar
            Center(
              child: SizedBox(
                width: 242,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottomGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (_amountController.text.trim().isEmpty || _totalBRLController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os valores primeiro')));
                      return;
                    }
                    
                    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
                    final double totalBRL = double.tryParse(_totalBRLController.text.replaceAll(',', '.')) ?? 0;
                    
                    if (amount <= 0 || totalBRL <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valores devem ser maiores que zero')));
                      return;
                    }
                    
                    final double vet = totalBRL / amount;

                    final transaction = CurrencyTransaction(
                      id: widget.transaction?.id,
                      userId: widget.userId,
                      amount: amount,
                      currency: _selectedCurrency,
                      amountBrl: totalBRL,
                      source: _selectedOrigin,
                      date: "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
                      vetRate: vet,
                      description: _descriptionController.text.trim(),
                    );
                    
                    final walletDao = WalletDAO();
                    final transactionDao = CurrencyTransactionDAO();
                    
                    if (widget.transaction != null) {
                      // Estamos editando. Precisamos reverter o impacto da transaction antiga no wallet e somar a nova
                      final oldAmount = widget.transaction!.amount;
                      final oldBrl = widget.transaction!.amountBrl;
                      
                      await transactionDao.updateTransaction(transaction);
                      
                      final wallet = await walletDao.getWallet(widget.userId, _selectedCurrency);
                      if (wallet != null) {
                        double newBalance = (wallet.balance - oldAmount) + amount;
                        // Para um VET puramente médio, a lógica real precisaria somar todos os BRL / todas as amounts.
                        // Calculo simplificado para refletir a nova adição:
                        // Descobre o BRL total antigo:
                        double totalBrlAntigo = wallet.balance * wallet.averageVet;
                        double novoTotalBrl = (totalBrlAntigo - oldBrl) + totalBRL;
                        double newVet = newBalance > 0 ? (novoTotalBrl / newBalance) : 0;
                        
                        await walletDao.updateWallet(Wallet(
                          userId: widget.userId,
                          currency: _selectedCurrency,
                          balance: newBalance,
                          averageVet: newVet,
                        ));
                      }
                    } else {
                      await transactionDao.insertTransaction(transaction);
                      
                      final wallet = await walletDao.getWallet(widget.userId, _selectedCurrency);
                      if (wallet != null) {
                        double newBalance = wallet.balance + amount;
                        double totalBrlAntigo = wallet.balance * wallet.averageVet;
                        double novoTotalBrl = totalBrlAntigo + totalBRL;
                        double newVet = novoTotalBrl / newBalance;
                        
                        await walletDao.updateWallet(Wallet(
                          userId: widget.userId,
                          currency: _selectedCurrency,
                          balance: newBalance,
                          averageVet: newVet,
                        ));
                      } else {
                        await walletDao.insertWallet(Wallet(
                          userId: widget.userId,
                          currency: _selectedCurrency,
                          balance: amount,
                          averageVet: vet,
                        ));
                      }
                    }
                    
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Salvar", style: TextStyle(color: AppColors.offWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
