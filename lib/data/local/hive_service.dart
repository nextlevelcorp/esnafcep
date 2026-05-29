import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../../core/constants/app_constants.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(ProductAdapter());
    await Hive.openBox<Sale>(AppConstants.salesBox);
    await Hive.openBox<Customer>(AppConstants.customersBox);
    await Hive.openBox<Expense>(AppConstants.expensesBox);
    await Hive.openBox<Payment>(AppConstants.paymentsBox);
    await Hive.openBox<Product>(AppConstants.productsBox);
    await Hive.openBox(AppConstants.settingsBox);
  }

  static Box<Sale> get salesBox => Hive.box<Sale>(AppConstants.salesBox);
  static Box<Customer> get customersBox => Hive.box<Customer>(AppConstants.customersBox);
  static Box<Expense> get expensesBox => Hive.box<Expense>(AppConstants.expensesBox);
  static Box<Payment> get paymentsBox => Hive.box<Payment>(AppConstants.paymentsBox);
  static Box<Product> get productsBox => Hive.box<Product>(AppConstants.productsBox);
  static Box get settingsBox => Hive.box(AppConstants.settingsBox);
}
