import 'package:flutter/material.dart';

class HistoryFilter extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;
  final DateTime? selectedDate; // New: track the selected date
  final Function(DateTime?) onDateSelected; // New: callback for date picker

  const HistoryFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ["All Scans", "Infected", "Healthy"];

    return SizedBox(
      height: 45, // Slightly increased height for better tap targets
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // 1. Date Picker Trigger
          _buildDateChip(context),
          
          const SizedBox(width: 10),
          
          // 2. Vertical Divider for visual separation
          VerticalDivider(
            color: Colors.white.withAlpha(77),
            thickness: 1,
            indent: 10,
            endIndent: 10,
          ),
          
          const SizedBox(width: 10),

          // 3. Existing Status Filters
          ...filters.map((filter) {
            bool isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onFilterSelected(filter),
                selectedColor: const Color(0xFF2D6A4F),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.withAlpha(26)),
                elevation: isSelected ? 4 : 0,
                shadowColor: Colors.black26,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateChip(BuildContext context) {
    bool hasDate = selectedDate != null;

    return ActionChip(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF2D6A4F), // Header background color
                  onPrimary: Colors.white,    // Header text color
                  onSurface: Color(0xFF1B3022), // Body text color
                ),
              ),
              child: child!,
            );
          },
        );
// If user picks the same date again, clear it — acts as a toggle
        if (picked != null && selectedDate != null &&
            picked.year == selectedDate!.year &&
            picked.month == selectedDate!.month &&
            picked.day == selectedDate!.day) {
          onDateSelected(null); // clear
        } else {
          onDateSelected(picked);
        }
              },
      avatar: Icon(
        hasDate ? Icons.event_available : Icons.calendar_month_outlined,
        size: 16,
        color: hasDate ? Colors.white : Colors.black87,
      ),
      label: Text(
        hasDate 
          ? "${selectedDate!.day}/${selectedDate!.month}" 
          : "Date",
        style: TextStyle(
          color: hasDate ? Colors.white : Colors.black87,
          fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: hasDate ? const Color(0xFF2D6A4F) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: Colors.grey.withAlpha(26)),
    );
  }
}