import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/pumo_ai_character.dart';
import '../services/pumo_ai_service.dart';
import '../services/pumo_storage_service.dart';
import '../constants/pumo_constants.dart';

class PumoCharacterCreationScreen extends StatefulWidget {
  const PumoCharacterCreationScreen({super.key});

  @override
  State<PumoCharacterCreationScreen> createState() => _PumoCharacterCreationScreenState();
}

class _PumoCharacterCreationScreenState extends State<PumoCharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personalityController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  Future<void> _generateDescription() async {
    if (_nameController.text.trim().isEmpty || _personalityController.text.trim().isEmpty) {
      _showSnackBar('Please enter name and personality first', isError: true);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final description = await PumoAIService.generateCharacterDescription(
        name: _nameController.text.trim(),
        personality: _personalityController.text.trim(),
      );
      _descriptionController.text = description;
    } catch (e) {
      _showSnackBar('Failed to generate description: $e', isError: true);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _createCharacter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final character = AICharacter(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        personality: _personalityController.text.trim(),
        avatarUrl: '', // 可以后续添加头像功能
        systemPrompt: await PumoAIService.generateSystemPrompt(
          name: _nameController.text.trim(),
          personality: _personalityController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
        createdAt: now,
        updatedAt: now,
      );

        await PumoStorageService.saveCharacter(character);
      
      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('Character created successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to create character: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create AI Character'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCharacter,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PumoConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: PumoConstants.largePadding),
              _buildNameField(),
              const SizedBox(height: PumoConstants.defaultPadding),
              _buildPersonalityField(),
              const SizedBox(height: PumoConstants.defaultPadding),
              _buildDescriptionField(),
              const SizedBox(height: PumoConstants.largePadding),
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.smart_toy,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Your AI Character',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Design a unique AI character with its own personality and traits',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Character Name',
        hintText: 'Enter a name for your AI character',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a character name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildPersonalityField() {
    return TextFormField(
      controller: _personalityController,
      decoration: const InputDecoration(
        labelText: 'Personality',
        hintText: 'e.g., Friendly, Helpful, Creative, Funny',
        prefixIcon: Icon(Icons.psychology),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please describe the character\'s personality';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Description',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _isGenerating ? null : _generateDescription,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(_isGenerating ? 'Generating...' : 'Generate'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'Describe your character\'s background, traits, and behavior',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a character description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createCharacter,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Creating Character...'),
              ],
            )
          : const Text('Create Character'),
    );
  }
}
