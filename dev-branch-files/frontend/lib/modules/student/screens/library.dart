// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/app_state.dart';

class LibraryScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const LibraryScreen({super.key, this.onNavigate});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _opacSearchCondition = 'All Fields'; // 'All Fields', 'Any Fields'
  String _opacResourceType = 'Books'; // 'Books', 'Reference', 'Project'
  String _opacSelectedField = '--Select--'; // '--Select--', 'Title', 'Author', 'Category', 'ISBN'
  final TextEditingController _opacDataController = TextEditingController();
  final TextEditingController _opacYearFromController = TextEditingController();
  final TextEditingController _opacYearToController = TextEditingController();
  bool _opacSearchClicked = false;

  @override
  void dispose() {
    _opacDataController.dispose();
    _opacYearFromController.dispose();
    _opacYearToController.dispose();
    super.dispose();
  }

  // Available books mock data with cover colors, copies count, and rack coordinates
  final List<Map<String, dynamic>> _availableBooks = [
    
  ];

  // Issued books mock data (Max 5 books)
  final List<Map<String, dynamic>> _issuedBooks = [
  
  ];

  int _selectedTab = 0; // 0: Available Books, 1: Issued Books, 2: Transaction History
  String _bookSearchQuery = '';

  // Transaction History mock data
  final List<Map<String, dynamic>> _transactionHistory = [
    
  ];

  List<Color> _getBookColors(String category) {
    switch (category.toLowerCase()) {
      case 'computer science':
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
      case 'database systems':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case 'operating systems':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'networking':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'software engineering':
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      default:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
  }

  String _getBookRack(BookModel book) {
    if (book.category.toLowerCase().contains('database')) return 'DB-01';
    if (book.category.toLowerCase().contains('operating')) return 'OS-02';
    if (book.category.toLowerCase().contains('network')) return 'NW-04';
    if (book.category.toLowerCase().contains('software')) return 'SE-01';
    if (book.category.toLowerCase().contains('intelligence')) return 'AI-05';
    return 'CS-03';
  }

  String _getBookShelf(BookModel book) {
    final ascii = 65 + (book.id.hashCode % 4).abs();
    return String.fromCharCode(ascii);
  }

  int _getBookCopies(BookModel book) {
    return (book.id.hashCode % 4).abs() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final List<Map<String, dynamic>> finalIssued = appState.libraryTransactions
        .where((t) => t['type']?.toString().toLowerCase() == 'issue' || (t['is_active'] == true && t['type']?.toString().toLowerCase() == 'reserve'))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabButton(
                  title: 'Available Books',
                  icon: Icons.menu_book_outlined,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                const SizedBox(width: 16),
                _buildTabButton(
                  title: 'Issued Books',
                  icon: Icons.assignment_outlined,
                  isSelected: _selectedTab == 1,
                  badgeText: '${finalIssued.length}/5 Max',
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                const SizedBox(width: 16),
                _buildTabButton(
                  title: 'Transaction History',
                  icon: Icons.history_outlined,
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          if (_selectedTab == 0) ...[
            _buildAvailableBooksView(appState),
          ] else if (_selectedTab == 1) ...[
            _buildIssuedBooksView(appState),
          ] else ...[
            _buildTransactionHistoryView(appState),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBooksView(AppState appState) {
    final filtered = appState.books.where((book) {
      if (!_opacSearchClicked) {
        return true;
      }
      
      final dataQuery = _opacDataController.text.trim().toLowerCase();
      if (dataQuery.isNotEmpty) {
        bool matchesData = false;
        if (_opacSelectedField == 'Title') {
          matchesData = book.title.toLowerCase().contains(dataQuery);
        } else if (_opacSelectedField == 'Author') {
          matchesData = book.author.toLowerCase().contains(dataQuery);
        } else if (_opacSelectedField == 'Category') {
          matchesData = book.category.toLowerCase().contains(dataQuery);
        } else if (_opacSelectedField == 'ISBN') {
          matchesData = book.isbn.toLowerCase().contains(dataQuery);
        } else {
          final matchesTitle = book.title.toLowerCase().contains(dataQuery);
          final matchesAuthor = book.author.toLowerCase().contains(dataQuery);
          final matchesCategory = book.category.toLowerCase().contains(dataQuery);
          final matchesIsbn = book.isbn.toLowerCase().contains(dataQuery);
          matchesData = matchesTitle || matchesAuthor || matchesCategory || matchesIsbn;
        }
        if (!matchesData) return false;
      }
      
      final fromStr = _opacYearFromController.text.trim();
      final toStr = _opacYearToController.text.trim();
      final bookYear = book.id.hashCode % 15 + 2010; // Deterministic year for display
      if (fromStr.isNotEmpty) {
        final fromYear = int.tryParse(fromStr);
        if (fromYear != null && bookYear < fromYear) return false;
      }
      if (toStr.isNotEmpty) {
        final toYear = int.tryParse(toStr);
        if (toYear != null && bookYear > toYear) return false;
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resource Filter (OPAC) Form
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0B2265), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF0B2265),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text(
                  'Resource Filter (OPAC)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF7CA4D9),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selections row
                    LayoutBuilder(builder: (context, box) {
                      final isWide = box.maxWidth > 700;
                      final searchCondWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Search Condition:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2265), fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'All Fields',
                                groupValue: _opacSearchCondition,
                                activeColor: const Color(0xFF0B2265),
                                onChanged: (v) => setState(() => _opacSearchCondition = v!),
                              ),
                              const Text('All Fields', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                              const SizedBox(width: 12),
                              Radio<String>(
                                value: 'Any Fields',
                                groupValue: _opacSearchCondition,
                                activeColor: const Color(0xFF0B2265),
                                onChanged: (v) => setState(() => _opacSearchCondition = v!),
                              ),
                              const Text('Any Fields', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ],
                      );

                      final resourceTypeWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resource type:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2265), fontSize: 13)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'Books',
                                  groupValue: _opacResourceType,
                                  activeColor: const Color(0xFF0B2265),
                                  onChanged: (v) => setState(() => _opacResourceType = v!),
                                ),
                                const Text('Books', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                const SizedBox(width: 8),
                                Radio<String>(
                                  value: 'Non Books',
                                  groupValue: _opacResourceType,
                                  activeColor: const Color(0xFF0B2265),
                                  onChanged: (v) => setState(() => _opacResourceType = v!),
                                ),
                                const Text('Non Books', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                                const SizedBox(width: 8),
                                Radio<String>(
                                  value: 'All',
                                  groupValue: _opacResourceType,
                                  activeColor: const Color(0xFF0B2265),
                                  onChanged: (v) => setState(() => _opacResourceType = v!),
                                ),
                                const Text('All', style: TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                        ],
                      );

                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                        children: [
                          isWide ? Expanded(child: searchCondWidget) : searchCondWidget,
                          if (!isWide) const SizedBox(height: 12),
                          isWide ? Expanded(child: resourceTypeWidget) : resourceTypeWidget,
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    // Field and Data
                    LayoutBuilder(builder: (context, box) {
                      final isWide = box.maxWidth > 700;
                      final fieldWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Field', style: TextStyle(color: Color(0xFF0B2265), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _opacSelectedField,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0B2265)),
                                onChanged: (val) => setState(() => _opacSelectedField = val!),
                                items: ['--Select--', 'Title', 'Author', 'Category', 'ISBN']
                                    .map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      );

                      final dataWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data', style: TextStyle(color: Color(0xFF0B2265), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            child: TextField(
                              controller: _opacDataController,
                              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), isDense: true),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      );

                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                        children: [
                          isWide ? Expanded(child: fieldWidget) : fieldWidget,
                          if (!isWide) const SizedBox(height: 12),
                          if (isWide) const SizedBox(width: 24),
                          isWide ? Expanded(child: dataWidget) : dataWidget,
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    // Publication Year and Action Buttons
                    LayoutBuilder(builder: (context, box) {
                      final isWide = box.maxWidth > 800;
                      final pubYearWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Publication Year', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2265), fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('From:', style: TextStyle(fontSize: 12, color: Color(0xFF0B2265), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: TextField(
                                    controller: _opacYearFromController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), isDense: true),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('To:', style: TextStyle(fontSize: 12, color: Color(0xFF0B2265), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 34,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                                  child: TextField(
                                    controller: _opacYearToController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), isDense: true),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );

                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.stretch,
                        children: [
                          isWide ? Expanded(child: pubYearWidget) : pubYearWidget,
                          const SizedBox(height: 16),
                          if (isWide) const SizedBox(width: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _opacSearchClicked = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007BFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text('SEARCH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _opacDataController.clear();
                                    _opacYearFromController.clear();
                                    _opacYearToController.clear();
                                    _opacSelectedField = '--Select--';
                                    _opacSearchCondition = 'All Fields';
                                    _opacResourceType = 'Books';
                                    _opacSearchClicked = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C757D),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text('CLEAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 60),
            alignment: Alignment.center,
            child: Column(
              children: const [
                Icon(Icons.library_books_outlined, size: 48, color: Color(0xFF94A3B8)),
                SizedBox(height: 12),
                Text('No books found matching your search.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = width > 1200 ? 3 : (width > 800 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  mainAxisExtent: 260,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final book = filtered[index];
                  final isReserved = book.isReserved;
                  final colors = _getBookColors(book.category);
                  final rack = _getBookRack(book);
                  final shelf = _getBookShelf(book);
                  final copies = _getBookCopies(book);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Container(
                          width: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  book.category.toUpperCase(),
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.menu_book, color: Colors.white, size: 24),
                              Text(
                                book.title,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(book.author, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF475569)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rack: $rack, Shelf: $shelf',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.copy_all, size: 12, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text('Available Copies: $copies', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      appState.toggleBookReservation(book.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isReserved ? const Color(0xFFDCFCE7) : const Color(0xFF1D4ED8),
                                      foregroundColor: isReserved ? const Color(0xFF16A34A) : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      isReserved ? '✓ Reserved' : 'Reserve Book',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildIssuedBooksView(AppState appState) {
    final List<Map<String, dynamic>> finalIssued = appState.libraryTransactions.isNotEmpty
        ? appState.libraryTransactions
            .where((t) => t['type']?.toString().toLowerCase() == 'issue' || (t['is_active'] == true && t['type']?.toString().toLowerCase() == 'reserve'))
            .map((t) {
              final b = appState.books.firstWhere((book) => book.id == t['book_id']?.toString(), orElse: () => BookModel(id: '', title: t['book_title'] ?? 'Unknown Book', author: t['book_author'] ?? 'Unknown Author', isbn: '', category: ''));
              return {
                'sNo': 1,
                'bookId': t['book_id']?.toString() ?? '',
                'bookName': b.title,
                'authorName': b.author,
                'issueDate': t['created_at'] != null ? t['created_at'].toString().split('T')[0] : DateTime.now().toString().split(' ')[0],
                'lastDate': t['due_date']?.toString() ?? '',
                'overdueDays': 0,
                'finePerDay': 10,
              };
            }).toList()
        : _issuedBooks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final titleCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Issued Books Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text('Note: A student can issue a maximum of 5 books at a time.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            );

            final badgeWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: const Text('Overdue Fine: ₹10 / day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleCol,
                  const SizedBox(height: 10),
                  badgeWidget,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleCol),
                const SizedBox(width: 12),
                badgeWidget,
              ],
            );
          }),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                DataColumn(label: Text('Book Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Author Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Issue Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Last Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Overdue Days', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Overdue Fine', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              ],
              rows: finalIssued.map((book) {
                final int overdueDays = book['overdueDays'] ?? 0;
                final int fineAmount = overdueDays * (book['finePerDay'] as int? ?? 10);

                return DataRow(
                  cells: [
                    DataCell(Center(child: Text('${book['sNo'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))))),
                    DataCell(Text(book['bookName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    DataCell(Text(book['authorName'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(Text(book['issueDate'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(Text(book['lastDate'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(overdueDays > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                            child: Text('$overdueDays days', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 12)),
                          )
                        : const Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                    DataCell(overdueDays > 0
                        ? Text('₹', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)))
                        : const Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryView(AppState appState) {
    final List<Map<String, dynamic>> finalHistory = appState.libraryTransactions.isNotEmpty
        ? appState.libraryTransactions
            .map((t) {
              final b = appState.books.firstWhere((book) => book.id == t['book_id']?.toString(), orElse: () => BookModel(id: '', title: t['book_title'] ?? 'Unknown Book', author: t['book_author'] ?? 'Unknown Author', isbn: '', category: ''));
              return {
                'sNo': 1,
                'bookId': t['book_id']?.toString() ?? '',
                'bookName': b.title,
                'authorName': b.author,
                'issueDate': t['created_at'] != null ? t['created_at'].toString().split('T')[0] : DateTime.now().toString().split(' ')[0],
                'dueDate': t['due_date']?.toString() ?? '',
                'returnDate': t['is_active'] == false ? 'Returned' : '-',
                'overdueDetails': '-',
                'overdueDays': 0,
                'fineAmount': 0,
              };
            }).toList()
        : _transactionHistory;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final titleCol = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Library Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                SizedBox(height: 4),
                Text('Past book issues, return dates, and overdue status details', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            );

            final badgeWidget = Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history, size: 16, color: Color(0xFF475569)),
                  SizedBox(width: 6),
                  Text('Completed Transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ],
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleCol,
                  const SizedBox(height: 10),
                  badgeWidget,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleCol),
                const SizedBox(width: 12),
                badgeWidget,
              ],
            );
          }),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Center(child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))))),
                DataColumn(label: Text('Book ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Book Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Author Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Issue Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Return Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                DataColumn(label: Text('Overdue Status & Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              ],
              rows: finalHistory.map((item) {
                final int overdueDays = item['overdueDays'] ?? 0;

                return DataRow(
                  cells: [
                    DataCell(Center(child: Text('${item['sNo'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155))))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(item['bookId'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12)),
                      ),
                    ),
                    DataCell(Text(item['bookName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    DataCell(Text(item['authorName'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(Text(item['issueDate'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(Text(item['returnDate'] ?? '', style: const TextStyle(color: Color(0xFF475569)))),
                    DataCell(overdueDays > 0
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                                child: Text('$overdueDays Days Overdue', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              Text(item['overdueDetails'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          )
                        : const Text('-', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
