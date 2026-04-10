// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'registration.dart'; // Since they are in the same folder
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   // Controllers to get text from fields
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   // State variables for validation errors
//   String? _emailError;
//   String? _passwordError;

//   // Hex Color Constant
//   final Color primaryGreen = const Color(0xFF16A34A);

//   void _handleLogin() {
//     // Reset errors before checking
//     setState(() {
//       _emailError = null;
//       _passwordError = null;
//     });

//     // Logical check for the specific error states you provided
//     if (_emailController.text.isEmpty) {
//       setState(() {
//         _emailError = "আপনার মোবাইল নম্বরটি অথবা ইমেইলটি নিবন্ধিত নয়";
//       });
//     } else if (_passwordController.text.length < 6) {
//       setState(() {
//         _passwordError = "আপনার পাসওয়ার্ডটি সঠিক নয়, আবার চেষ্টা করুন";
//       });
//     } else {
//       // Proceed to Home or Database check
//       print("Login Successful");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const SizedBox(height: 60),
//                 SvgPicture.asset("assets/images/Logo.svg", height: 100),
//                 // 2. Login Card Container
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.grey.shade200),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.05),
//                         blurRadius: 15,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "লগইন",
//                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                       const Text(
//                         "ট্রাভেল পাস অ্যাকাউন্টে লগইন করুন",
//                         style: TextStyle(color: Colors.grey, fontSize: 14),
//                       ),
//                       const SizedBox(height: 30),

//                       // Mobile/Email Label & Field
//                       const Text("মোবাইল/ইমেইল", style: TextStyle(fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                           hintText: "মোবাইল/ইমেইল (ইংরেজিতে)",
//                           errorText: _emailError,
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 20),

//                       // Password Label & Field
//                       const Text("পাসওয়ার্ড", style: TextStyle(fontWeight: FontWeight.w600)),
//                       const SizedBox(height: 8),
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           hintText: "পাসওয়ার্ড",
//                           errorText: _passwordError,
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                       ),

//                       // Forgot Password
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: () {},
//                           child: const Text(
//                             "পাসওয়ার্ড ভুলে গেছেন?",
//                             style: TextStyle(color: Colors.black87, fontSize: 13),
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 10),

//                       // Login Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _handleLogin,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryGreen,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                           ),
//                           child: const Text(
//                             "লগইন করুন",
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 // 3. Registration Footer
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("ট্রাভেল পাস অ্যাকাউন্ট নেই? "),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const RegistrationScreen()),
//                         );
//                       },
//                       child: Text(
//                         "রেজিস্ট্রেশন করুন",
//                         style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
// }
