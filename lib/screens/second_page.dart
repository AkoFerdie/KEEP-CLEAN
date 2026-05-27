import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'signin_page.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ✅ Responsive Curves
          _buildTopLeftCurve(screenWidth),
          _buildTopRightCurve(screenWidth),
          _buildBottomLeftCurve(screenWidth),
          _buildBottomRightCurve(screenWidth),

          // ✅ Main Content (Scrollable)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight * 0.8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Responsive Logo
                      Image.asset(
                        'assets/front_logo.png',
                        width: screenWidth * 0.3,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Title
                      Text(
                        'Keep It Clean',
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                        ),
                        child: Text(
                          'Tackling the pressing issues of dirty roads and neighborhoods in order to create a friendly environment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // ✅ Responsive Sign In Button
                      SizedBox(
                        width: screenWidth * 0.7,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // ✅ Responsive Sign Up Button
                      SizedBox(
                        width: screenWidth * 0.7,
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Responsive Curves

  Widget _buildTopLeftCurve(double screenWidth) {
    return Positioned(
      top: -screenWidth * 0.2,
      left: -screenWidth * 0.25,
      child: Container(
        width: screenWidth * 0.7,
        height: screenWidth * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(200),
            bottomRight: Radius.circular(200),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightCurve(double screenWidth) {
    return Positioned(
      top: -screenWidth * 0.2,
      right: -screenWidth * 0.25,
      child: Container(
        width: screenWidth * 0.7,
        height: screenWidth * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(200),
            bottomRight: Radius.circular(200),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLeftCurve(double screenWidth) {
    return Positioned(
      bottom: -screenWidth * 0.2,
      left: -screenWidth * 0.25,
      child: Container(
        width: screenWidth * 0.7,
        height: screenWidth * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(200),
            topRight: Radius.circular(200),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRightCurve(double screenWidth) {
    return Positioned(
      bottom: -screenWidth * 0.2,
      right: -screenWidth * 0.25,
      child: Container(
        width: screenWidth * 0.7,
        height: screenWidth * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF4CAF50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(200),
            topRight: Radius.circular(200),
          ),
        ),
      ),
    );
  }
}