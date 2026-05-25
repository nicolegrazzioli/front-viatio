import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

import '../core/models/currency_transaction.dart';
import '../core/models/wallet.dart';
import '../core/dao/currency_transaction_dao.dart';
import '../core/dao/wallet_dao.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/trip_provider.dart';

class NewCurrencyPurchaseScreen extends StatefulWidget {
  final String userId;
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

  
  String _selectedCurrency = 'EUR';
  final List<String> _currencies = ['BRL', 'USD', 'EUR'];
  
  String _selectedOrigin = 'Wise';
  final List<String> _origins = ['Wise', 'Revolut', 'Picnic', 'Inter', 'Papel/Câmbio'];
  
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateVET);
    _totalBRLController.addListener(_updateVET);

    if (widget.transaction != null) {
      final data = widget.transaction!;
      _amountController.text = data.amount.toString();
      _totalBRLController.text = data.amountBrl.toString();
      _selectedCurrency = data.currency;
      
      String origin = data.source;
      if (!_origins.contains(origin)) {
        // Se a origem do gasto antigo não estiver na lista fixa, adiciona ela só pra podermos editar sem perder o dado
        _origins.add(origin);
      }
      _selectedOrigin = origin;
      

      try {
        final dateParts = data.date.split('/');
        _selectedDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _totalBRLController.dispose();

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
                        await context.read<WalletProvider>().removeTransaction(transaction);
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
                          if (newValue != null) {
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
                    if (newValue != null) {
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
                    lastDate: DateTime.now(),
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

                    );
                    
                    final walletProvider = context.read<WalletProvider>();
                    final authProvider = context.read<AuthProvider>();
                    
                    if (widget.transaction != null) {
                      await walletProvider.editTransaction(transaction, widget.transaction!);
                    } else {
                      await walletProvider.addTransaction(transaction);
                    }
                    
                    final user = authProvider.currentUser;
                    if (user != null) {
                      // Recarrega as viagens para garantir que o efeito cascata do VET seja refletido na UI
                      await context.read<TripProvider>().loadTrips(user.id!, fetchApi: false);
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
