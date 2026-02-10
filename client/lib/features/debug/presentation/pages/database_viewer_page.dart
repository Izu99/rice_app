// The entire content of this file is commented out because it relies on DbHelper,
// which is part of the removed local SQLite storage.
// This file is no longer relevant for the API-only architecture.

/*
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rice_mill_erp/core/constants/db_constants.dart';
import 'package:rice_mill_erp/core/database/db_helper.dart';

import '../widgets/table_view_widget.dart'; // Import the new widget

class DatabaseViewerPage extends StatefulWidget {
  const DatabaseViewerPage({super.key});

  @override
  State<DatabaseViewerPage> createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  final DbHelper _dbHelper = GetIt.instance<DbHelper>();
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<String> _tableNames = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTableNames();
  }

  Future<void> _loadTableNames() async {
    try {
      // DbHelper doesn't expose table names directly, so manually list them from DbConstants
      _tableNames = const [
        DbConstants.usersTable,
        DbConstants.customersTable,
        DbConstants.stockTable,
        DbConstants.transactionsTable,
        DbConstants.transactionItemsTable,
        DbConstants.paymentsTable,
        DbConstants.companiesTable,
        DbConstants.millingTable,
        DbConstants.syncQueueTable,
        DbConstants.settingsTable,
        DbConstants.auditLogTable,
      ];
      _tableNames.sort(); // Sort alphabetically for easier navigation
      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load table names: $e';
      });
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() {
      _selectedTable = tableName;
      _tableData = [];
      _errorMessage = null;
    });

    try {
      final data = await _dbHelper.query(tableName);
      setState(() {
        _tableData = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data for $tableName: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTableNames();
              if (_selectedTable != null) {
                _loadTableData(_selectedTable!);
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Table Names List
          SizedBox(
            width: 150,
            child: ListView.builder(
              itemCount: _tableNames.length,
              itemBuilder: (context, index) {
                final tableName = _tableNames[index];
                return ListTile(
                  title: Text(tableName),
                  selected: _selectedTable == tableName,
                  onTap: () => _loadTableData(tableName),
                );
              },
            ),
          ),
          // Table Data View
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _selectedTable == null
                    ? const Center(
                        child: Text('Select a table to view data'),
                      )
                    : TableViewWidget(
                        tableName: _selectedTable!,
                        data: _tableData,
                      ),
          ),
        ],
      ),
    );
  }
}
*/
