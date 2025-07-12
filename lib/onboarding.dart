// onboarding.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yummeal/auth_service.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  final _authService = AuthService();

  int currentStep = 0;
  final int totalSteps = 6; // Bez AI kroku

  // Data collection
  String firstName = '';
  String lastName = '';
  String gender = '';
  int age = 25;
  double targetWeight = 60;
  int height = 170;
  double currentWeight = 45;
  int activityLevel = 1;

  void _nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getGenderValue(String genderText) {
    switch (genderText) {
      case 'Male':
        return 1;
      case 'Female':
        return 2;
      default:
        return 0; // Other
    }
  }

  int _getWeightGoal() {
    if (currentWeight > targetWeight) {
      return 2; // Lose weight
    } else if (currentWeight < targetWeight) {
      return 1; // Gain weight
    } else {
      return 3; // Maintain weight
    }
  }

  Future<void> _completeOnboarding() async {
    print('===== STARTING ONBOARDING COMPLETION =====');

    try {
      // Sprawdź czy użytkownik jest zalogowany
      final isLoggedIn = await _authService.isLoggedIn();
      final userData = await _authService.getUserData();
      final token = await _authService.getToken();

      print('Onboarding check - isLoggedIn: $isLoggedIn');
      print('Onboarding check - userData: $userData');
      print(
        'Onboarding check - token: ${token?.substring(0, 20)}...' ?? 'null',
      );

      // Debug - sprawdź dane przed zapisem
      print('Saving onboarding data:');
      print('FirstName: $firstName');
      print('LastName: $lastName');
      print('Age: $age');
      print('Gender: ${_getGenderValue(gender)}');
      print('Height: $height');
      print('CurrentWeight: ${currentWeight.round()}');
      print('TargetWeight: ${targetWeight.round()}');
      print('WeightGoal: ${_getWeightGoal()}');
      print('ActivityLevel: $activityLevel');

      // ZAWSZE zapisz dane lokalnie (niezależnie od API)
      final currentUserData = await _authService.getUserData() ?? {};

      // Dodaj wszystkie dane onboardingu
      currentUserData['isOnboardingCompleted'] = true;
      currentUserData['firstName'] = firstName;
      currentUserData['FirstName'] = firstName; // Backup
      currentUserData['lastName'] = lastName;
      currentUserData['LastName'] = lastName; // Backup
      currentUserData['Age'] = age;
      currentUserData['Gender'] = _getGenderValue(gender);
      currentUserData['Height'] = height;
      currentUserData['CurrentWeight'] = currentWeight.round();
      currentUserData['TargetWeight'] = targetWeight.round();
      currentUserData['WeightGoal'] = _getWeightGoal();
      currentUserData['ActivityLevel'] = activityLevel;

      // Zapisz lokalne dane
      await _authService.saveAuthDataPublic(currentUserData);
      print('Local data saved with onboarding completion');

      // Spróbuj wysłać do API (jeśli token istnieje)
      if (isLoggedIn && token != null) {
        try {
          final onboardingData = {
            'firstName': firstName,
            'lastName': lastName,
            'age': age,
            'gender': _getGenderValue(gender),
            'height': height,
            'currentWeight': currentWeight.round(),
            'targetWeight': targetWeight.round(),
            'weightGoal': _getWeightGoal(),
            'activityLevel': activityLevel,
          };

          final result = await _authService.completeOnboarding(onboardingData);
          print('API onboarding completion result: $result');
        } catch (apiError) {
          print('API error but continuing with local data: $apiError');
          // Kontynuuj nawet jeśli API nie działa
        }
      } else {
        print('No token available, skipping API call but keeping local data');
      }

      if (mounted) {
        // Pokaż komunikat sukcesu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile created successfully! Welcome to Yummeal! ✨',
            ),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        // ZAWSZE przejdź do home page po zapisaniu danych
        print('Navigating to home page after onboarding completion');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Critical error in onboarding completion: $e');
      print('Error type: ${e.runtimeType}');

      if (mounted) {
        // Nawet przy błędzie, spróbuj zapisać podstawowe dane lokalnie
        try {
          final basicUserData = await _authService.getUserData() ?? {};
          basicUserData['isOnboardingCompleted'] = true;
          basicUserData['firstName'] = firstName;
          basicUserData['FirstName'] = firstName;
          await _authService.saveAuthDataPublic(basicUserData);

          // Przejdź do home nawet przy błędzie
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (saveError) {
          print('Failed to save even basic data: $saveError');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: currentStep > 0 ? _previousStep : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 16,
                            color:
                                currentStep > 0
                                    ? Colors.black
                                    : Colors.grey[400],
                          ),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  currentStep > 0
                                      ? Colors.black
                                      : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: List.generate(totalSteps, (index) {
                          return Expanded(
                            child: Container(
                              height: 8,
                              margin: EdgeInsets.only(
                                right: index < totalSteps - 1 ? 4 : 0,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    index <= currentStep
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(),
                  _buildGenderStep(),
                  _buildAgeStep(),
                  _buildHeightStep(),
                  _buildCurrentWeightStep(),
                  _buildGoalWeightStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'What\'s your first name?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will be shown on your profile',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => setState(() => firstName = value),
              decoration: const InputDecoration(
                hintText: 'Enter your first name',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) => setState(() => lastName = value),
              decoration: const InputDecoration(
                hintText: 'Enter your last name (optional)',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: firstName.isNotEmpty ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Choose your gender',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us create a more personalized plan\nfor you',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          _buildGenderOption('Male'),
          const SizedBox(height: 16),
          _buildGenderOption('Female'),
          const SizedBox(height: 16),
          _buildGenderOption('Other'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: gender.isNotEmpty ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String option) {
    final isSelected = gender == option;
    return GestureDetector(
      onTap: () => setState(() => gender = option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF4CAF50),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'What\'s your age?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your metabolism',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 80),

          // Age picker
          SizedBox(
            height: 300,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.003,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: age - 13, // Start from 13 years old
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  age = index + 13; // 13-100 years old
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 88, // 13 to 100 years old
                builder: (context, index) {
                  final currentAge = index + 13;
                  final isSelected = currentAge == age;

                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$currentAge years',
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeightStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'What\'s your height?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need this for accurate calculations',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 80),

          // Height picker
          SizedBox(
            height: 300,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.003,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: height - 120, // Start from 120cm
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  height = index + 120; // 120-220 cm
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 101, // 120cm to 220cm
                builder: (context, index) {
                  final currentHeight = index + 120;
                  final isSelected = currentHeight == height;

                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${currentHeight}cm',
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCurrentWeightStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'What\'s your current weight?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is your starting point',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 80),

          // Current weight picker
          SizedBox(
            height: 300,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.003,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: currentWeight.round() - 30, // Start from 30kg
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  currentWeight = (index + 30).toDouble(); // 30-200kg
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 171, // 30kg to 200kg
                builder: (context, index) {
                  final weight = index + 30;
                  final isSelected = weight == currentWeight.round();

                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weight}kg',
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGoalWeightStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Set your goal weight',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll use it to personalize your plan',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 80),

          // Weight picker with scroll
          SizedBox(
            height: 300,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.003,
              diameterRatio: 1.5,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: targetWeight.round() - 30, // Current selection
              ),
              onSelectedItemChanged: (index) {
                setState(() {
                  targetWeight = (index + 30).toDouble(); // Start from 30kg
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 171, // 30kg to 200kg (171 options)
                builder: (context, index) {
                  final weight = index + 30;
                  final isSelected = weight == targetWeight.round();

                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${weight}kg',
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 60),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _completeOnboarding(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Complete Setup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
