import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/models/expense.dart';
import '../core/models/wallet.dart';
import '../core/models/user.dart';
import '../core/dao/expense_dao.dart';
import '../core/dao/userDAO.dart';
import '../core/dao/wallet_dao.dart';
import '../core/authentication/auth_service.dart';

class NewExpenseScreen extends StatefulWidget {
  final String tripId;
  final String tripTitle;
  final Expense? expense;

  const NewExpenseScreen({
    super.key, 
    required this.tripId,
    required this.tripTitle,
    this.expense,
  });

  @override

  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  String _selectedCurrency = 'BRL';
  final List<String> _currencies = ['BRL', 'USD', 'EUR'];
  List<Wallet>? _wallets;
  
  DateTime? _selectedDate = DateTime.now();
  bool _useAverageCost = true;
  String? _selectedCategory;
  
  final List<String> _categories = [
    'Alimentação', 'Mercado', 'Transporte', 'Hospedagem', 
    'Lazer', 'Compras', 'Burocracia (visto, taxa, seguro)', 'Saúde (farmácia, consulta)'
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController(text: '1.0');
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final data = widget.expense!;
      _titleController.text = data.title;
      _amountController.text = data.amount.toString();
      _selectedCurrency = data.currency;
      _selectedCategory = data.category;
      _exchangeRateController.text = data.exchangeRate?.toString() ?? '1.0';
      _descriptionController.text = data.description ?? '';
      _useAverageCost = data.isAverageCost;
      try {
        final dateParts = data.date.split('/');
        _selectedDate = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
    _loadCurrenciesAndVET();
  }

  Future<void> _loadCurrenciesAndVET() async {
    User? user = AuthService.currentUser;
    if (user == null) return;
    if (user != null) {
      final wallets = await WalletDAO().getWalletsByUser(user.id!);
      if (mounted) {
        setState(() {
          _wallets = wallets;
        });
        _updateExchangeRate();
      }
    }
  }

  void _updateExchangeRate() {
    if (_useAverageCost && _wallets != null) {
      if (_selectedCurrency == 'BRL') {
        _exchangeRateController.text = '1.0';
      } else {
        final wallet = _wallets!.cast<Wallet?>().firstWhere(
          (w) => w!.currency == _selectedCurrency, 
          orElse: () => null,
        );
        if (wallet != null) {
          _exchangeRateController.text = wallet.averageVet.toStringAsFixed(2);
        } else {
          _exchangeRateController.text = '1.0';
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.moneyGreen,
              onPrimary: Colors.white,
              surface: AppColors.darkBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTextField({
    required String hint, 
    TextEditingController? controller, 
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.silverBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white54, 
          fontSize: 16, 
          fontWeight: FontWeight.w300
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w300),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        title: Column(
          children: [
            Text(widget.tripTitle, style: const TextStyle(color: AppColors.offWhite, fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
            Text(widget.expense != null ? "editar gasto" : "novo gasto", style: const TextStyle(color: AppColors.offWhite, fontSize: 20, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 80,
        actions: widget.expense != null ? [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // Confirmar exclusão do gasto
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: const Text("Excluir Gasto", style: TextStyle(color: Colors.white)),
                  content: const Text("Tem certeza que deseja excluir este gasto?", style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white))),
                    TextButton(
                      onPressed: () async {
                        await ExpenseDAO().deleteExpense(widget.expense!.id!);
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
            // Título
            _buildTextField(hint: "Título", controller: _titleController),
            const SizedBox(height: 24),

            // Valor e Moeda
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    hint: "Valor", 
                    controller: _amountController, 
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                            setState(() {
                              _selectedCurrency = newValue;
                            });
                            _updateExchangeRate();
                          }
                        },
                        items: _currencies.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
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
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                label: Text(
                  _selectedDate == null 
                    ? "Data" 
                    : "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}", 
                  style: TextStyle(
                    color: _selectedDate == null ? Colors.white70 : Colors.white, 
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

            // Custo Médio e Câmbio
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Custo médio",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
                        ),
                      ),
                      Switch(
                        value: _useAverageCost,
                        onChanged: (val) {
                          setState(() {
                            _useAverageCost = val;
                          });
                          if (val) {
                            _updateExchangeRate();
                          }
                        },
                        activeColor: AppColors.moneyGreen,
                        activeTrackColor: AppColors.moneyGreen.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    hint: "Câmbio",
                    controller: _exchangeRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_useAverageCost,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Categorias
            const Text(
              "Categoria",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          _selectedCategory == category 
                            ? Icons.radio_button_checked 
                            : Icons.radio_button_unchecked,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Descrição (Opcional)
            _buildTextField(hint: "Descrição (opcional)", controller: _descriptionController),
            const SizedBox(height: 48),

            // Botão Salvar
            Center(
              child: SizedBox(
                width: 242,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottomGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty || _selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha título, valor e categoria')));
                      return;
                    }

                    final double amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
                    final double exchangeRate = double.tryParse(_exchangeRateController.text.replaceAll(',', '.')) ?? 1.0;
                    final double amountBrl = amount * exchangeRate;
                    final DateTime dt = _selectedDate ?? DateTime.now();

                    final newExpense = Expense(
                      id: widget.expense?.id,
                      tripId: widget.tripId,
                      title: _titleController.text.trim(),
                      amount: amount,
                      currency: _selectedCurrency,
                      category: _selectedCategory!,
                      date: "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}",
                      isAverageCost: _useAverageCost,
                      exchangeRate: exchangeRate,
                      amountBrl: amountBrl,
                      description: _descriptionController.text.trim(),
                    );

                    if (widget.expense != null) {
                      await ExpenseDAO().updateExpense(newExpense);
                    } else {
                      await ExpenseDAO().insertExpense(newExpense);
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "Salvar",
                    style: TextStyle(
                      color: AppColors.offWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
