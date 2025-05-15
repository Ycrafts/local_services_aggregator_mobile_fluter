import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/job_type.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _proposedPriceController = TextEditingController();
  JobType? _selectedJobType;
  bool _isLoading = false;
  List<JobType> _jobTypes = [];

  @override
  void initState() {
    super.initState();
    _loadJobTypes();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _proposedPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadJobTypes() async {
    try {
      final apiService = context.read<ApiService>();
      print('Fetching job types...'); // Debug print
      final jobTypes = await apiService.getJobTypes();
      print('Loaded job types: $jobTypes'); // Debug print
      if (mounted) {
        setState(() {
          _jobTypes = jobTypes;
        });
      }
    } catch (e) {
      print('Error loading job types: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job types: $e')),
        );
      }
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate() || _selectedJobType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      await apiService.postJob(
        jobTypeId: _selectedJobType!.id,
        description: _descriptionController.text,
        proposedPrice: double.parse(_proposedPriceController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Job Type Dropdown
                    DropdownButtonFormField<JobType>(
                      value: _selectedJobType,
                      decoration: const InputDecoration(
                        labelText: 'Job Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _jobTypes.map((jobType) {
                        return DropdownMenuItem(
                          value: jobType,
                          child: Text('${jobType.name} (Baseline Price: ${jobType.baselinePrice.toStringAsFixed(2)} Birr)'),
                        );
                      }).toList(),
                      onChanged: (JobType? value) {
                        setState(() {
                          _selectedJobType = value;
                          if (value != null) {
                            _proposedPriceController.text = value.baselinePrice.toString();
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a job type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Describe the job in detail',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Proposed Price Field
                    TextFormField(
                      controller: _proposedPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Proposed Price',
                        border: OutlineInputBorder(),
                        suffixText: 'Birr',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a proposed price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 1) {
                          return 'Price must be at least 1 Birr';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitJob,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Post Job'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 