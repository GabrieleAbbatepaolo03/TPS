import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:officer_interface/SERVICES/controller_service.dart';

class TicketData {
  final String reason;
  final String notes;
  final File? image;
  final double amount; 

  TicketData({
    required this.reason, 
    required this.notes, 
    this.image,
    required this.amount, 
  });
}

class IssueTicketDialog extends StatefulWidget {
  final String plate;
  final int? sessionId;

  const IssueTicketDialog({
    super.key,
    required this.plate,
    this.sessionId,
  });

  @override
  State<IssueTicketDialog> createState() => _IssueTicketDialogState();
}

class _IssueTicketDialogState extends State<IssueTicketDialog> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // SOSTITUITA LA MAPPA FISSA CON LISTA DINAMICA E LOADING
  List<Map<String, dynamic>> _violationTypes = [];
  bool _isLoading = true;
  
  // Ora salviamo l'intero oggetto violazione selezionato
  Map<String, dynamic>? _selectedViolation;

  @override
  void initState() {
    super.initState();
    _loadViolationTypes();
  }

  // NUOVO METODO PER CARICARE DATI
  Future<void> _loadViolationTypes() async {
    try {
      final types = await ControllerService.fetchViolationTypes();
      if (mounted) {
        setState(() {
          _violationTypes = types;
          _isLoading = false;
          if (types.isNotEmpty) {
            _selectedViolation = types.first;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 50
    );
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcola il prezzo corrente in sicurezza
    double currentPrice = 0.0;
    if (_selectedViolation != null) {
       currentPrice = double.tryParse(_selectedViolation!['amount'].toString()) ?? 0.0;
    }

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 2, 11, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Issue Violation Ticket",
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReadOnlyField("License Plate", widget.plate, isBig: true),
            const SizedBox(height: 10),
            _buildReadOnlyField("Session ID", widget.sessionId != null ? "#${widget.sessionId}" : "N/A", isBig: true),
            
            const Divider(color: Colors.white24, height: 25),

            Text("Violation Type", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 5),
            
            // DROPDOWN DINAMICO
            _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white)))
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedViolation,
                      dropdownColor: const Color.fromARGB(255, 10, 20, 50),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: _violationTypes.map((type) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: type,
                          child: Text(type['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedViolation = val);
                      },
                    ),
                  ),
                ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Fine Amount: ",
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
                Text(
                  "€ ${currentPrice.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24, height: 25),

            // FOTO PROVE (Invariato)
            Text("Evidence Photo", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.white54, size: 30),
                          const SizedBox(height: 5),
                          Text("Tap to take photo", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // NOTE (Invariato)
            Text("Officer Notes", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 5),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add specific details...",
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _selectedViolation == null ? null : () {
            Navigator.pop(context, TicketData(
              reason: _selectedViolation!['name'],
              notes: _notesController.text.trim(),
              image: _selectedImage,
              amount: double.tryParse(_selectedViolation!['amount'].toString()) ?? 0.0,
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text("ISSUE TICKET", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, {bool isBig = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: isBig ? 22 : 16,
            letterSpacing: isBig ? 1.2 : 0,
          ),
        ),
      ],
    );
  }
}