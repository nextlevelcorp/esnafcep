import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/customer.dart';
import '../data/models/payment.dart';
import '../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

final customersProvider =
    StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) {
  return CustomersNotifier(ref.read(customerRepositoryProvider));
});

class CustomersNotifier extends StateNotifier<List<Customer>> {
  final CustomerRepository _repo;

  CustomersNotifier(this._repo) : super(_repo.getAllCustomers());

  void addCustomer({required String name, String? phone}) {
    final customer = Customer(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );
    _repo.addCustomer(customer);
    state = _repo.getAllCustomers();
  }

  void updateCustomer(Customer customer) {
    _repo.updateCustomer(customer);
    state = _repo.getAllCustomers();
  }

  void deleteCustomer(String id) {
    _repo.deleteCustomer(id);
    state = _repo.getAllCustomers();
  }

  void addDebt(String customerId, double amount) {
    final customer = _repo.getCustomer(customerId);
    if (customer == null) return;
    customer.totalDebt += amount;
    customer.lastDebtAt = DateTime.now();
    _repo.updateCustomer(customer);
    state = _repo.getAllCustomers();
  }

  void recordPayment({
    required String customerId,
    required double amount,
    String? note,
  }) {
    final customer = _repo.getCustomer(customerId);
    if (customer == null) return;
    final payment = Payment(
      id: const Uuid().v4(),
      customerId: customerId,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );
    _repo.addPayment(payment, customer);
    state = _repo.getAllCustomers();
  }

  List<Payment> getPayments(String customerId) =>
      _repo.getPaymentsByCustomer(customerId);

  Customer? getCustomer(String id) => _repo.getCustomer(id);

  List<Customer> get debtors => _repo.getDebtors();
}
