import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/models/trip.dart';
import '../core/providers/trip_provider.dart';
import 'package:provider/provider.dart';

class NewTripScreen extends StatefulWidget {
  final Trip? trip;
  final String? userId;
  const NewTripScreen({super.key, this.trip, this.userId});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  String _selectedCover = "Nenhuma";

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _titleController.text = widget.trip!.title;
      try {
        final startParts = widget.trip!.startDate.split('/');
        _startDate = DateTime(int.parse(startParts[2]), int.parse(startParts[1]), int.parse(startParts[0]));
        
        final endParts = widget.trip!.endDate?.split('/');
        _endDate = DateTime(int.parse(endParts![2]), int.parse(endParts[1]), int.parse(endParts[0]));
      } catch (e) {
        _startDate = DateTime.now();
      }
      
      final coverMatch = _covers.firstWhere((c) => c["url"] == widget.trip!.coverType, orElse: () => {"name": "Praia"});
      _selectedCover = coverMatch["name"]!;
    } else {
      _selectedCover = _covers[0]["name"]!;
    }
  }

  final List<Map<String, String>> _covers = [
    {"name": "Praia", "url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e"},
    {"name": "Natureza", "url": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e"},
    {"name": "Urbano", "url": "https://images.unsplash.com/photo-1449824913935-59a10b8d2000"},
    {"name": "Cultural", "url": "https://images.unsplash.com/photo-1518709268805-4e9042af9f23"},
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now()),
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
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
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
          widget.trip != null ? "Editar viagem" : "Nova viagem",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Título",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.silverBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.moneyGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Datas
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker("Início", _startDate, () => _selectDate(context, true)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDatePicker("Fim", _endDate, () => _selectDate(context, false)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            const Text(
              "Capa",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            // Grid de Capas
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: _covers.length,
              itemBuilder: (context, index) {
                final cover = _covers[index];
                final isSelected = _selectedCover == cover["name"];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCover = cover["name"]!),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.moneyGreen : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(cover["url"]!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(isSelected ? 0.2 : 0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cover["name"]!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 48),
            
            // Botões
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moneyGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Por favor, preencha o título da viagem.'),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  
                  final trip = Trip(
                    id: widget.trip?.id,
                    userId: widget.userId ?? widget.trip!.userId, 
                    title: _titleController.text.trim(),
                    startDate: "${_startDate.day.toString().padLeft(2,'0')}/${_startDate.month.toString().padLeft(2,'0')}/${_startDate.year}",
                    endDate: _endDate != null ? "${_endDate!.day.toString().padLeft(2,'0')}/${_endDate!.month.toString().padLeft(2,'0')}/${_endDate!.year}" : null,
                    coverType: _covers.firstWhere((c) => c["name"] == _selectedCover)["url"]!,
                  );

                  try {
                    if (widget.trip != null) {
                      await context.read<TripProvider>().editTrip(trip);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viagem atualizada com sucesso!'), backgroundColor: AppColors.moneyGreen));
                    } else {
                      await context.read<TripProvider>().addTrip(trip);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viagem criada com sucesso!'), backgroundColor: AppColors.moneyGreen));
                    }
                  } catch (e) {
                    print("Erro ao salvar viagem: $e");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
                  }
                  
                  if (mounted) Navigator.pop(context);
                },
                child: const Text(
                  "Salvar",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Botões de Excluir removidos daqui pois estão no menu ⋮ da tela de detalhes
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.silverBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? label : "${date.day}/${date.month}/${date.year}",
              style: TextStyle(color: date == null ? Colors.white70 : Colors.white),
            ),
            const Icon(Icons.calendar_month, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
