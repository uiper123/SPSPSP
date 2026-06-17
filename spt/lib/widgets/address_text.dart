import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressText extends StatefulWidget {
  final String? initialLocation;
  final String coordinates;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;

  const AddressText({
    super.key,
    this.initialLocation,
    required this.coordinates,
    required this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<AddressText> {
  String? _resolvedAddress;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation == null || widget.initialLocation!.isEmpty) {
      _resolveAddress();
    }
  }

  Future<void> _resolveAddress() async {
    if (widget.coordinates.isEmpty) return;
    if (_isResolving) return;

    setState(() {
      _isResolving = true;
    });

    try {
      final parts = widget.coordinates.split(',');
      if (parts.length != 2) throw Exception('Invalid coordinates');

      final lat = parts[0].trim();
      final lng = parts[1].trim();

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=ru',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'SpotfynderApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? '';
        if (mounted && address.toString().isNotEmpty) {
          setState(() {
            _resolvedAddress = address.toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Error resolving address: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayAddress = '';

    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      displayAddress = widget.initialLocation!;
    } else if (_resolvedAddress != null && _resolvedAddress!.isNotEmpty) {
      displayAddress = _resolvedAddress!;
    } else if (_isResolving) {
      displayAddress = 'Определяем адрес...';
    } else {
      displayAddress = widget.coordinates.isNotEmpty
          ? widget.coordinates
          : 'Адрес неизвестен';
    }

    return Text(
      displayAddress,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
