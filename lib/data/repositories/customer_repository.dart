import 'package:hive/hive.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../local/hive_service.dart';

class CustomerRepository {
  Box<Customer> get _box => HiveService.customersBox;
  Box<Payment> get _paymentBox => HiveService.paymentsBox;

  void addCustomer(Customer customer) => _box.put(customer.id, customer);

  void updateCustomer(Customer customer) => _box.put(customer.id, customer);

  void deleteCustomer(String id) => _box.delete(id);

  List<Customer> getAllCustomers() =>
      _box.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  List<Customer> getDebtors() =>
      _box.values.where((c) => c.totalDebt > 0).toList()
        ..sort((a, b) => b.totalDebt.compareTo(a.totalDebt));

  Customer? getCustomer(String id) => _box.get(id);

  void addPayment(Payment payment, Customer customer) {
    _paymentBox.put(payment.id, payment);
    customer.totalDebt = (customer.totalDebt - payment.amount).clamp(0, double.infinity);
    _box.put(customer.id, customer);
  }

  List<Payment> getPaymentsByCustomer(String customerId) {
    return _paymentBox.values.where((p) => p.customerId == customerId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
