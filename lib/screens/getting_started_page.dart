import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'second_page.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});

  static const _heroImage = AssetImage('assets/Picture2.png');
  static const _logoImage = AssetImage('assets/front_logo.png');

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: h * 0.45,
                          width: double.infinity,
                          child: const Image(
                            image: _heroImage,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                        SizedBox(height: h * 0.015),
                        Center(
                          child: Image(
                            image: _logoImage,
                            width: w * 0.22,
                            height: w * 0.22,
                            gaplessPlayback: true,
                          ),
                        ),
                        SizedBox(height: h * 0.01),
                        Text(
                          'Keep It Clean',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: w * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.1, vertical: h * 0.01),
                          child: Text(
                            'Join our community to keep our environment clean and join cleanup efforts',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: w * 0.035,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.025),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(vertical: h * 0.02),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SecondPage()),
                              );
                            },
                            child: Text(
                              'Get Started',
                              style: TextStyle(fontSize: w * 0.042, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
