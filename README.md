# NAZ ENTERPRISES Desktop ERP

A comprehensive, production-grade desktop ERP system built with Flutter and Dart, designed specifically for small to medium businesses to manage their complete business operations with ease and efficiency.

## 📋 Overview

NAZ ENTERPRISES is a feature-rich ERP application that provides integrated solutions for financial management, sales, inventory, payroll, and more. Built with Flutter for cross-platform desktop support (Windows, Linux, macOS), it combines a modern UI with robust backend capabilities powered by SQLite for local data persistence.

## 🎯 Core Features

### 📊 Dashboard & Analytics
- **Real-time KPIs**: At-a-glance view of key performance indicators with dynamic business metrics
- **Visual Analytics**: Graphical charts and data visualization using FL Chart library
- **Business Intelligence**: Comprehensive dashboard providing quick insights into business health

### 💰 Financial Management
- **General Ledger**: Complete double-entry bookkeeping system with debit/credit transactions
- **Chart of Accounts**: Organized account hierarchy for different transaction categories
- **Bank Reconciliation**: Tools to match bank statements with ledger entries
- **Ledger Entries**: Detailed transaction tracking with voucher numbers, references, and descriptions
- **Financial Reporting**: Generate comprehensive financial statements and reports

### 👥 Customer & Vendor Management
- **Unified Contact Management**: Single interface for managing both customers and vendors
- **Customer Profiles**: Maintain customer details including address, mobile, NTN, opening balance
- **Vendor Tracking**: Track vendor information and payment history
- **Ledger Integration**: View individual customer/vendor ledgers with transaction history
- **Customer Ledger Table**: Detailed transaction view for each customer with running balances

### 📝 Sales & Invoicing
- **Invoice Creation**: Create and manage sales invoices with line items
- **Invoice Tracking**: Monitor invoice status, payments, and delivery
- **Sales Reporting**: Track sales performance and customer transactions
- **Invoice Repository**: Comprehensive invoice history and audit trail

### 📦 Inventory Management
- **Product Management**: Organize products with categorization and detailed attributes
- **Stock Tracking**: Real-time inventory levels and stock movements
- **Pricing**: Manage cost price and selling price for each item
- **Stock Transactions**: Record purchases, sales, and adjustments
- **Low Stock Alerts**: Monitor items below minimum stock levels
- **Inventory Valuation**: Calculate inventory value and cost of goods
- **Item Ledger**: Track complete history of each item's transactions

### 🛢️ Cans Management
- **Returnable Asset Tracking**: Specialized module for tracking cans and similar returnable assets
- **Opening & Current Balance**: Maintain can counts with opening and closing balances
- **Cans Entries**: Record can transactions with vouchers and descriptions
- **Cans Ledger**: Complete history of can movements by account

### 💳 Purchases & Expenses
- **Purchase Orders**: Create and track purchase orders
- **Expense Management**: Record and categorize business expenses
- **Payment Methods**: Track payments via different payment methods
- **Expense Categories**: Organize expenses by category for better reporting
- **Purchase History**: Complete audit trail of all purchases

### 👔 Payroll Management
- **Employee Management**: Maintain employee profiles and details
- **Payroll Processing**: Calculate and process employee salaries
- **Payroll History**: Track payment history and deductions
- **Employee Records**: Comprehensive employee database

### 🔄 Automation & Data Management
- **CSV Import**: Import data from CSV files for bulk operations
- **Excel Export**: Export reports and data to Excel format
- **Data Migration**: Automate data import/export workflows
- **Batch Operations**: Perform bulk operations on records

### 📑 Reporting & Analytics
- **Sales Reports**: Detailed sales analysis and trends
- **Purchase Reports**: Comprehensive purchase tracking and analytics
- **Inventory Reports**: Stock levels, valuations, and movements
- **Financial Reports**: Income statements, trial balances, and ledger reports
- **Custom Reports**: Flexible reporting framework for various analyses

## 🛠️ Technical Architecture

### Tech Stack
- **Framework**: Flutter 3.0+ (Cross-platform desktop application)
- **Language**: Dart 3.9.0+
- **State Management**: GetX (Reactive state management and dependency injection)
- **Database**: SQLite with `sqflite_common_ffi` for desktop support
- **UI Components**:
  - Material Design 3
  - Syncfusion Flutter DataGrid (Advanced data tables)
  - FL Chart (Data visualization)
  - Flutter ScreenUtil (Responsive design)
  - Google Fonts (Typography)
- **Data Handling**:
  - CSV parsing and export (`csv` package)
  - Excel operations (`excel` package)
- **PDF Generation**: `pdf` library with `printing` support
- **Window Management**: `window_manager` for desktop window controls
- **Utilities**:
  - `intl` (Internationalization and date formatting)
  - `shared_preferences` (Local preferences storage)
  - `url_launcher` (External link handling)
  - `path_provider` (File system paths)

### Project Structure

```
lib/
├── main.dart                          # Application entry point & Dashboard
├── core/
│   ├── database/
│   │   └── db_helper.dart            # SQLite database initialization & schema
│   ├── models/                        # Data models (9 core entities)
│   │   ├── ledger.dart
│   │   ├── customer.dart
│   │   ├── vendor.dart
│   │   ├── invoice.dart
│   │   ├── item.dart
│   │   ├── employee.dart
│   │   ├── payroll.dart
│   │   ├── cans.dart
│   │   ├── bank_transaction.dart
│   │   ├── expense.dart
│   │   ├── purchase.dart
│   │   └── stock_transaction.dart
│   ├── repositories/                 # Core business logic repositories
│   │   ├── kpi_repository.dart       # Dashboard KPI calculations
│   │   └── cans_repository.dart      # Cans tracking logic
│   ├── service_bindings.dart         # GetX dependency injection setup
│   ├── theme/
│   │   └── app_theme.dart            # Light/Dark themes with Material Design 3
│   └── utils/                        # Helper utilities
│
├── features/                          # Feature modules (9 main modules)
│   ├── ledger/
│   │   ├── ledger_home.dart
│   │   ├── ledger_repository.dart
│   │   └── [related components]
│   │
│   ├── customer_vendor/
│   │   ├── customer_list.dart
│   │   ├── customer_repository.dart
│   │   ├── customer_ledger_table.dart
│   │   └── [customer management UI]
│   │
│   ├── inventory/
│   │   ├── item_list.dart
│   │   ├── inventory_repository.dart
│   │   └── [inventory management]
│   │
│   ├── sales_invoicing/
│   │   ├── invoice_list.dart
│   │   ├── invoice_repository.dart
│   │   └── [invoice UI components]
│   │
│   ├── purchases_expenses/
│   │   ├── purchase_and_expense_list_and_form.dart
│   │   ├── purchase_expense_repository.dart
│   │   └── [expense tracking UI]
│   │
│   ├── bank_reconciliation/
│   │   ├── bank_transaction_list.dart
│   │   ├── bank_repository.dart
│   │   └── [reconciliation tools]
│   │
│   ├── cans/
│   │   ├── cans_list.dart
│   │   └── [cans tracking UI]
│   │
│   ├── payroll/
│   │   ├── employee_list.dart
│   │   ├── payroll_repository.dart
│   │   └── [payroll processing]
│   │
│   └── automation/
│       ├── automation_screen.dart
│       ├── export_repository.dart
│       ├── csv_import_repository.dart
│       └── [import/export tools]
│
└── shared/
    ├── components/                  # Reusable UI components
    ├── widgets/                     # Navigation and common widgets
    └── [shared utilities]
```

### Database Schema
The application uses SQLite with the following core tables:
- `ledger` - General ledger entries (debit/credit transactions)
- `ledger_entries_*` - Dynamic tables for individual ledger entries
- `customer` - Customer information and profiles
- `item` - Product/inventory items
- `stock_transaction` - Inventory movements
- `expense_purchases` - Expense and purchase records
- `cans` - Can/returnable asset accounts
- `cans_entries` - Can transaction history
- Dynamic tables for customer/item ledger entries

### Architecture Highlights
- **MVC Pattern**: Repositories handle business logic, UI handles presentation
- **GetX State Management**: Lazy-loaded dependencies, reactive UI updates
- **Repository Pattern**: Centralized database access and business logic
- **Service Bindings**: Dependency injection for all repositories and controllers
- **Responsive Design**: Flutter ScreenUtil for adaptive layouts across devices
- **Theme Management**: Dark/Light mode with Material Design 3 principles

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.9.0 or higher (included with Flutter)
- **Windows/Linux/macOS**: Desktop development enabled

Verify your setup:
```bash
flutter --version
dart --version
flutter config --enable-windows-desktop  # For Windows
flutter config --enable-linux-desktop    # For Linux
flutter config --enable-macos-desktop    # For macOS
```

### Installation & Setup

```bash
# 1. Clone the repository
git clone https://github.com/umerfarooq123-codei/naz.github.io.git
cd naz_enterprises

# 2. Install dependencies
flutter pub get

# 3. Run the application
# For Windows:
flutter run -d windows

# For Linux:
flutter run -d linux

# For macOS:
flutter run -d macos
```

### Building for Production

```bash
# Build Windows executable
flutter build windows --release
# Output: build/windows/x64/runner/Release/

# Build Linux AppImage
flutter build linux --release
# Output: build/linux/x64/release/bundle/

# Build macOS app
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### Database Setup

The application uses SQLite database stored at:
- **Windows**: `C:\Users\<Username>\AppData\Local\naz_enterprises\ledger_app.db`
- **Linux**: `~/.local/share/naz_enterprises/ledger_app.db`
- **macOS**: `~/Library/Application Support/naz_enterprises/ledger_app.db`

> **⚠️ CRITICAL WARNING: Destructive Migrations**
> The current database migration strategy is destructive. Upgrading the `version` number in `lib/core/database/db_helper.dart` will **drop all existing tables and permanently delete all user data**. Always back up the database file before making any changes or running a new version of the application.

## 📖 Usage Guide

### Starting the Application
1. Run `flutter run -d windows` (or your target platform)
2. The app opens with the Dashboard view displaying KPIs
3. Navigate between modules using the sidebar menu

### Core Workflows

#### Creating a Ledger Entry
1. Go to **Ledger** module
2. Select an account or create a new one
3. Enter transaction details (debit/credit amounts, date, description)
4. Assign a voucher number for tracking
5. Save - entry automatically updates account balances

#### Managing Customers/Vendors
1. Open **Customer & Vendor** module
2. Create new contact or edit existing
3. View individual ledger showing all transactions
4. Track opening balances and outstanding amounts

#### Processing Sales
1. Navigate to **Sales & Invoicing**
2. Create new invoice with customer and items
3. Specify quantities and prices
4. Generate and track invoice status
5. Link to ledger for financial reporting

#### Inventory Operations
1. Go to **Inventory** module
2. Add/edit items with cost and selling prices
3. Track stock levels and movements
4. Monitor low-stock alerts
5. View complete item ledger history

#### Expense Tracking
1. Open **Purchases & Expenses**
2. Record expense with category and payment method
3. Attach reference numbers for audit trail
4. View expense reports by category

#### Payroll Processing
1. Access **Payroll** module
2. Maintain employee records
3. Process monthly salaries
4. View payment history and deductions

#### Data Import/Export
1. Go to **Automation** module
2. **Export**: Select data type (ledger, customers, inventory) and export to CSV/Excel
3. **Import**: Upload CSV file with proper format to import bulk data

## 🎨 UI/UX Features

- **Responsive Design**: Adapts to various screen sizes using Flutter ScreenUtil
- **Dark/Light Mode**: Switch between themes via settings
- **Data Grid**: Advanced Syncfusion grids for large datasets
- **Visual Charts**: FL Chart integration for data visualization
- **Material Design 3**: Modern, professional UI following latest design standards
- **Professional Typography**: Google Fonts for clean typography

## 🔧 Development Guide

### Adding a New Feature Module

1. Create feature folder: `lib/features/new_feature/`
2. Create repository: `new_feature_repository.dart`
3. Create controller(s) using GetX
4. Create UI screens
5. Add repository to `service_bindings.dart`
6. Add navigation in sidebar

### Database Schema Modifications

1. Edit `_createAllTables()` in `db_helper.dart`
2. Increment `version` number
3. Implement `_onUpgrade()` logic if needed
4. Migration recreates tables with new schema

### State Management (GetX)

```dart
// Using GetX for reactive updates
class MyController extends GetxController {
  var data = <Item>[].obs;

  void fetchData() {
    data.assignAll(repository.getItems());
  }
}

// In UI
Obx(() => ListView(children: _controller.data));
```

### Database Operations

```dart
// Get database instance
final db = await DBHelper().database;

// Execute query
final results = await db.query('customer', where: 'id = ?', whereArgs: [1]);

// Insert
await db.insert('customer', customerMap);

// Update
await db.update('customer', customerMap, where: 'id = ?', whereArgs: [id]);

// Delete
await db.delete('customer', where: 'id = ?', whereArgs: [id]);
```

## 📊 Key Classes & Controllers

### Service Bindings
- Initializes all repositories lazily using GetX
- Registers controllers for dependency injection
- Called at app startup via `ServiceBindings()`

### Core Repositories
- `LedgerRepository` - General ledger operations
- `CustomerRepository` - Customer CRUD and ledger
- `InventoryRepository` - Item and stock management
- `InvoiceRepository` - Invoice processing
- `ExpensePurchaseRepository` - Expense tracking
- `PayrollRepository` - Payroll operations
- `BankRepository` - Bank reconciliation
- `CansRepository` - Returnable asset tracking
- `ExportRepository` - CSV/Excel export
- `CSVImportRepository` - CSV data import
- `KPIRepository` - Dashboard metrics calculation

### UI Controllers
- `LedgerController` - Ledger module state
- `CustomerController` - Customer management state
- `ItemController` - Inventory management state
- `ExpensePurchaseGetxController` - Expense module state
- `AutomationController` - Import/export operations
- `ThemeController` - Application theme management

## 🐛 Troubleshooting

### Database Issues
- **"Database locked" error**: Check for concurrent access; app uses WAL mode for better concurrency
- **Missing tables**: Ensure database version is updated; reinstall app to reset
- **Data not persisting**: Verify SQLite is properly initialized; check database path

### UI Issues
- **Blank screens**: Check GetX dependencies are properly initialized in `ServiceBindings`
- **Responsive layout issues**: Verify Flutter ScreenUtil configuration
- **Theme not changing**: Clear SharedPreferences cache and restart app

### Performance Issues
- **Slow data loading**: Check database indexes; consider pagination for large datasets
- **High memory usage**: Monitor large DataGrid loads; implement virtualization
- **UI lag**: Profile with Flutter DevTools; check for blocking main thread operations

## 📝 Code Style & Conventions

- **Naming**: camelCase for variables/functions, PascalCase for classes
- **Comments**: Use `///` for public APIs, `//` for implementation details
- **Imports**: Group by dart, flutter, packages, then project imports
- **Error Handling**: Use try-catch for database operations
- **Async Code**: Prefer `async`/`await` over futures

## 🚀 Performance Optimization

- **Database**: Uses SQLite pragmas for optimal performance (WAL, cache size, synchronous mode)
- **UI**: Lazy loading of repositories with GetX
- **Data Grids**: Implements virtual scrolling for large datasets
- **Theme**: Caches theme preference in SharedPreferences
- **Images**: Assets optimized for desktop displays

## 🔐 Security Considerations

- **Local Data**: All data stored locally in SQLite (consider adding encryption for sensitive data)
- **No Network**: Application doesn't sync to external servers by default
- **Access Control**: Implement user authentication for multi-user scenarios (future enhancement)
- **Data Backup**: Regularly backup `ledger_app.db` file to prevent data loss

## 📄 License

This project is proprietary software for NAZ ENTERPRISES. All rights reserved.

## 👥 Contributing

As a proprietary project, contributions are limited to team members. For development guidelines, see the internal documentation.

## 📞 Support & Contact

For issues, questions, or feature requests, please contact the NAZ ENTERPRISES development team.

---

**Last Updated**: December 31, 2025
**Version**: 1.0.0+1
**Status**: Active Development
**Framework**: Flutter 3.0.0+
**Database**: SQLite with Foreign Keys & WAL Mode