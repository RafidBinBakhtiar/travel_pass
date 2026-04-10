// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({super.key});

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   // 1. State for Radio Buttons
//   String _touristType = 'domestic';
//   bool _isPasswordVisible = false;

//   final Color primaryGreen = const Color(0xFF16A34A);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 40),
//               SvgPicture.asset("assets/images/Logo.svg", height: 100),

//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.grey.shade200),
//                   boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("নতুন অ্যাকাউন্ট তৈরি করুন", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                     const Text("সঠিক তথ্য দিয়ে নিচের ফর্মটি পূরণ করুন", style: TextStyle(color: Colors.grey, fontSize: 13)),
//                     const SizedBox(height: 20),

//                     // Full Name
//                     const Text("পূর্ণ নাম", style: TextStyle(fontWeight: FontWeight.bold)),
//                     _buildTextField("আপনার নাম লিখুন"),

//                     const SizedBox(height: 15),

//                     // Mobile Number with Flag Placeholder
//                     const Text("মোবাইল নম্বর", style: TextStyle(fontWeight: FontWeight.bold)),
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey.shade300),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: const Row(children: [Icon(Icons.flag, color: Colors.red, size: 20), Icon(Icons.arrow_drop_down)]),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(child: _buildTextField("0123467890")),
//                       ],
//                     ),

//                     const SizedBox(height: 15),

//                     // Email
//                     const Text("ইমেইল অ্যাড্রেস", style: TextStyle(fontWeight: FontWeight.bold)),
//                     _buildTextField("example@mail.com"),

//                     const SizedBox(height: 15),

//                     // Password
//                     const Text("পাসওয়ার্ড", style: TextStyle(fontWeight: FontWeight.bold)),
//                     TextFormField(
//                       obscureText: !_isPasswordVisible,
//                       decoration: InputDecoration(
//                         hintText: "পাসওয়ার্ড দিন",
//                         suffixIcon: IconButton(
//                           icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
//                           onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
//                         ),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                     ),

//                     // Password Requirements List
//                     Padding(
//                       padding: const EdgeInsets.only(top: 10, left: 5),
//                       child: Column(
//                         children: [
//                           _buildRequirement("অন্তত ৮টি অক্ষর হতে হবে"),
//                           _buildRequirement("একটি বড় হাতের অক্ষর (A-Z) ও একটি সংখ্যা (0-9) থাকতে হবে"),
//                           _buildRequirement("একটি বিশেষ চিহ্ন (যেমন: @, #, \$) থাকতে হবে"),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Tourist Type (Radio Buttons)
//                     const Text("পর্যটকের ধরণ", style: TextStyle(fontWeight: FontWeight.bold)),
//                     RadioListTile<String>(
//                       title: const Text("অভ্যন্তরীণ পর্যটক (Domestic Tourist)", style: TextStyle(fontSize: 14)),
//                       value: 'domestic',
//                       groupValue: _touristType,
//                       activeColor: primaryGreen,
//                       onChanged: (val) => setState(() => _touristType = val!),
//                     ),
//                     RadioListTile<String>(
//                       title: const Text("বিদেশি পর্যটক (Foreign Tourist)", style: TextStyle(fontSize: 14)),
//                       value: 'foreign',
//                       groupValue: _touristType,
//                       activeColor: primaryGreen,
//                       onChanged: (val) => setState(() => _touristType = val!),
//                     ),

//                     const SizedBox(height: 20),

//                     // Submit Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: () {},
//                         style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
//                         child: const Text("অ্যাকাউন্ট তৈরি করুন", style: TextStyle(fontSize: 16)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Back to Login
//               TextButton.icon(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back, size: 16),
//                 label: const Text("লগইন পেইজে ফিরে যান"),
//                 style: TextButton.styleFrom(foregroundColor: primaryGreen),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper widget for text fields
//   Widget _buildTextField(String hint) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0),
//       child: TextFormField(
//         decoration: InputDecoration(
//           hintText: hint,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12),
//         ),
//       ),
//     );
//   }

//   // Helper widget for password requirements
//   Widget _buildRequirement(String text) {
//     return Row(
//       children: [
//         const Icon(Icons.circle, size: 6, color: Colors.green),
//         const SizedBox(width: 8),
//         Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.green))),
//       ],
//     );
//   }
// }
