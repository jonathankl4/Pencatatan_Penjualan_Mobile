class Expense {
  final int id;
  final String name;
  final double amount;
  final String category;
  final String? notes;
  final String expenseDate;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.notes,
    required this.expenseDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      notes: json['notes'],
      expenseDate: json['expense_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'notes': notes,
      'expense_date': expenseDate,
    };
  }
}
