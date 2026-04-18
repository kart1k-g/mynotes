import 'package:flutter/material.dart';

InputDecoration authInputDecoration({
  required String label,
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon, color: const Color(0xFF99A9BF)),
    suffixIcon: suffixIcon,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(
      color: Color(0xFF182A4E),
      fontWeight: FontWeight.w700,
      fontSize: 22,
    ),
    hintStyle: const TextStyle(color: Color(0xFF96A2B4), fontSize: 17),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE4EDF5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF00A693), width: 1.3),
    ),
  );
}
