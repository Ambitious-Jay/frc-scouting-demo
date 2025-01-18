// NOTE: This was made but is honestly defunct now 
//import 'package:flutter/material.dart';

// class LabeledButton extends StatelessWidget {
//   final String label;
//   final Object buttonContent;
//   final Function() functionOnTap;

//   const LabeledButton(
//       {super.key,
//       required this.label,
//       required this.buttonContent,
//       required this.functionOnTap});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(label),
//         ElevatedButton(
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: Theme.of(context).colorScheme.primary,
//                 foregroundColor: Theme.of(context).colorScheme.secondary,
//                 minimumSize: const Size.square(70),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(5))),
//             onPressed: functionOnTap,
//             child: Text('$buttonContent')),
//       ],
//     );
//   }
// }
