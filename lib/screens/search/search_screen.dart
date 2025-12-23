import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/search_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/input_field.dart';
import '../../widgets/loader.dart';
import '../../utils/validators.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();

  @override
  void dispose() {
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    if (_formKey.currentState!.validate()) {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      final success = await searchProvider.searchByAadhar(_aadharController.text.trim());

      if (success && mounted) {
        if (searchProvider.searchResults.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultsScreen(
                transactions: searchProvider.searchResults,
                aadhar: _aadharController.text.trim(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions found for this Aadhaar number'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(searchProvider.error ?? 'Search failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Transactions',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.search,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Search by Aadhaar',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter Aadhaar number to view transaction history',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                InputField(
                  label: 'Aadhaar Number',
                  hint: 'Enter 12-digit Aadhaar',
                  controller: _aadharController,
                  validator: Validators.validateAadhar,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                const SizedBox(height: 32),
                Consumer<SearchProvider>(
                  builder: (context, searchProvider, _) {
                    if (searchProvider.isLoading) {
                      return const Loader(message: 'Searching...');
                    }
                    return PrimaryButton(
                      text: 'Search',
                      onPressed: _handleSearch,
                      isLoading: searchProvider.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

