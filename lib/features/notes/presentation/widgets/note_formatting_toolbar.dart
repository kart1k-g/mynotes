// import 'package:flutter/material.dart';
// import 'package:mynotes/features/notes/presentation/mynotes_theme.dart';

// /// Minimal formatting actions for plain text; inserts common markers around
// /// the current selection in [controller].
// class NoteFormattingToolbar extends StatelessWidget {
//   const NoteFormattingToolbar({required this.controller, super.key});

//   final TextEditingController controller;

//   void _wrap(String left, String right) {
//     final text = controller.text;
//     var sel = controller.selection;
//     if (!sel.isValid) {
//       sel = TextSelection.collapsed(offset: text.length);
//     }
//     final start = sel.start < 0 ? text.length : sel.start;
//     final end = sel.end < 0 ? text.length : sel.end;
//     final a = start.clamp(0, text.length);
//     final b = end.clamp(0, text.length);
//     final lo = a < b ? a : b;
//     final hi = a < b ? b : a;
//     final selected = text.substring(lo, hi);
//     final replacement = '$left$selected$right';
//     final newText = text.replaceRange(lo, hi, replacement);
//     controller.value = TextEditingValue(
//       text: newText,
//       selection: TextSelection.collapsed(
//         offset: lo + left.length + selected.length + right.length,
//       ),
//     );
//   }

//   void _insertPrefix(String prefix) {
//     final text = controller.text;
//     var sel = controller.selection;
//     if (!sel.isValid) {
//       sel = TextSelection.collapsed(offset: text.length);
//     }
//     final pos = sel.start.clamp(0, text.length);
//     var lineStart = text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0);
//     if (lineStart < 0) {
//       lineStart = -1;
//     }
//     final insertAt = lineStart + 1;
//     final newText = text.replaceRange(insertAt, insertAt, prefix);
//     controller.value = TextEditingValue(
//       text: newText,
//       selection: TextSelection.collapsed(offset: insertAt + prefix.length),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       elevation: 0,
//       color: Colors.white,
//       child: Container(
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             top: BorderSide(color: MyNotesColors.divider, width: 0.5),
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//         child: SafeArea(
//           top: false,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: IntrinsicHeight(
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   _icon(Icons.format_bold_rounded, () => _wrap('**', '**')),
//                   _icon(Icons.format_italic_rounded, () => _wrap('*', '*')),
//                   _icon(Icons.strikethrough_s_rounded, () => _wrap('~~', '~~')),
//                   _vDiv(),
//                   _icon(Icons.format_list_bulleted_rounded, () {
//                     _insertPrefix('- ');
//                   }),
//                   _icon(Icons.format_list_numbered_rounded, () {
//                     _insertPrefix('1. ');
//                   }),
//                   _vDiv(),
//                   _icon(Icons.link_rounded, () => _wrap('[', '](url)')),
//                   _icon(Icons.image_outlined, () {
//                     _wrap('![alt](', ')');
//                   }),
//                   _icon(Icons.label_outline_rounded, () {
//                     _insertPrefix('#');
//                   }),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _vDiv() => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 4),
//     child: Container(width: 0.5, height: 22, color: MyNotesColors.divider),
//   );

//   Widget _icon(IconData icon, VoidCallback onTap) {
//     return IconButton(
//       visualDensity: VisualDensity.compact,
//       padding: const EdgeInsets.all(10),
//       constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
//       onPressed: onTap,
//       icon: Icon(icon, size: 22, color: MyNotesColors.navy),
//     );
//   }
// }
