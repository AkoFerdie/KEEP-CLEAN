import 'package:flutter/material.dart';
import '../utils/theme_helper.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildSection('📚 Getting Started', _getGettingStartedItems()),
          const SizedBox(height: 20),
          _buildSection('♻️ Waste Management', _getWasteManagementItems()),
          const SizedBox(height: 20),
          _buildSection('🏖️ Beach Cleanup Guide', _getBeachCleanupItems()),
          const SizedBox(height: 20),
          _buildSection('🤝 For Organizations', _getOrganizationItems()),
          const SizedBox(height: 20),
          _buildSection('🏛️ For Government/Hysacam', _getGovernmentItems()),
          const SizedBox(height: 20),
          _buildSection('❓ FAQ & Support', _getFAQItems()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ThemeHelper.getCardShadow(context)],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: ThemeHelper.getTextColor(context)),
        decoration: InputDecoration(
          hintText: 'Search guides and tutorials...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
          hintStyle: TextStyle(color: ThemeHelper.getSecondaryTextColor(context)),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuickActionCard('Report Waste', Icons.report, Colors.orange, () => _showGuideDetail('How to Report Waste', _getReportWasteSteps()))),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard('Sort Waste', Icons.recycling, Colors.green, () => _showGuideDetail('Waste Sorting Guide', _getWasteSortingSteps()))),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickActionCard('Find Centers', Icons.location_on, Colors.blue, () => _showGuideDetail('Recycling Centers', _getRecyclingCenters()))),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [ThemeHelper.getCardShadow(context)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThemeHelper.getTextColor(context)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<GuideItem> items) {
    final filteredItems = _searchQuery.isEmpty 
        ? items 
        : items.where((item) => item.title.toLowerCase().contains(_searchQuery) || item.subtitle.toLowerCase().contains(_searchQuery)).toList();
    
    if (filteredItems.isEmpty && _searchQuery.isNotEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        const SizedBox(height: 12),
        ...filteredItems.map((item) => _buildGuideCard(item)),
      ],
    );
  }

  Widget _buildGuideCard(GuideItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ThemeHelper.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ThemeHelper.getCardShadow(context)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: const Color(0xFF4CAF50), size: 24),
        ),
        title: Text(item.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeHelper.getTextColor(context))),
        subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: ThemeHelper.getSecondaryTextColor(context))),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: ThemeHelper.getSecondaryTextColor(context).withValues(alpha: 0.7)),
        onTap: () => _showGuideDetail(item.title, item.content),
      ),
    );
  }

  void _showGuideDetail(String title, List<String> content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ThemeHelper.getCardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeHelper.getTextColor(context)))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: ThemeHelper.getTextColor(context))),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: content.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4, right: 12),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        ),
                        Expanded(child: Text(content[index], style: TextStyle(fontSize: 14, height: 1.5, color: ThemeHelper.getTextColor(context)))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Guide'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Enter search term...'),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  List<GuideItem> _getGettingStartedItems() {
    return [
      GuideItem('How to Report Waste', 'Step-by-step guide to reporting waste issues', Icons.report_outlined, _getReportWasteSteps()),
      GuideItem('Setting Up Your Profile', 'Complete your profile for better experience', Icons.person_outline, _getProfileSetupSteps()),
      GuideItem('Understanding the App', 'Navigate through all app features', Icons.apps_outlined, _getAppNavigationSteps()),
      GuideItem('First Time User Guide', 'Everything you need to know to get started', Icons.play_circle_outline, _getFirstTimeSteps()),
    ];
  }

  List<GuideItem> _getWasteManagementItems() {
    return [
      GuideItem('Waste Sorting Guide', 'Learn how to properly sort different types of waste', Icons.recycling_outlined, _getWasteSortingSteps()),
      GuideItem('Recycling Centers in Cameroon', 'Find nearby recycling facilities', Icons.location_on_outlined, _getRecyclingCenters()),
      GuideItem('Hazardous Waste Disposal', 'Safe handling of dangerous materials', Icons.warning_outlined, _getHazardousWasteGuide()),
      GuideItem('Composting at Home', 'Turn organic waste into useful compost', Icons.eco_outlined, _getCompostingSteps()),
      GuideItem('Plastic Reduction Tips', 'Reduce plastic usage in daily life', Icons.local_drink_outlined, _getPlasticReductionTips()),
    ];
  }

  List<GuideItem> _getBeachCleanupItems() {
    return [
      GuideItem('Limbe Beach Cleanup Schedule', 'When and where beach cleanups happen', Icons.schedule_outlined, _getLimbeSchedule()),
      GuideItem('What to Bring', 'Essential items for beach cleanup', Icons.backpack_outlined, _getBeachCleanupSupplies()),
      GuideItem('Safety Guidelines', 'Stay safe during cleanup activities', Icons.security_outlined, _getSafetyGuidelines()),
      GuideItem('Impact Measurement', 'How we track cleanup success', Icons.analytics_outlined, _getImpactMeasurement()),
    ];
  }

  List<GuideItem> _getOrganizationItems() {
    return [
      GuideItem('Creating Campaigns', 'How to organize cleanup campaigns', Icons.campaign_outlined, _getCampaignCreationSteps()),
      GuideItem('Volunteer Management', 'Recruit and coordinate volunteers', Icons.people_outline, _getVolunteerManagementSteps()),
      GuideItem('Partnership Building', 'Work with recycling companies', Icons.handshake_outlined, _getPartnershipSteps()),
      GuideItem('Impact Tracking', 'Measure your environmental impact', Icons.trending_up_outlined, _getImpactTrackingSteps()),
    ];
  }

  List<GuideItem> _getGovernmentItems() {
    return [
      GuideItem('Dashboard Overview', 'Understanding waste reports and data', Icons.dashboard_outlined, _getDashboardOverview()),
      GuideItem('Patrol Scheduling', 'Efficient waste collection routes', Icons.route_outlined, _getPatrolScheduling()),
      GuideItem('Data Analysis', 'Making sense of waste patterns', Icons.bar_chart_outlined, _getDataAnalysis()),
      GuideItem('Public Engagement', 'Involving citizens in waste management', Icons.public_outlined, _getPublicEngagement()),
    ];
  }

  List<GuideItem> _getFAQItems() {
    return [
      GuideItem('Common Issues', 'Solutions to frequent problems', Icons.help_outline, _getCommonIssues()),
      GuideItem('Contact Support', 'Get help when you need it', Icons.support_agent_outlined, _getContactInfo()),
      GuideItem('App Updates', 'What\'s new in recent versions', Icons.system_update_outlined, _getUpdateInfo()),
      GuideItem('Privacy & Security', 'How we protect your data', Icons.privacy_tip_outlined, _getPrivacyInfo()),
    ];
  }

  // Content methods
  List<String> _getReportWasteSteps() {
    return [
      'Open the app and tap on the "Post" tab in the bottom navigation',
      'Select "Post a Request" to create a new waste report',
      'Choose the location where you found the waste issue',
      'Enter your phone number for contact purposes',
      'Select the date and time when you noticed the issue',
      'Provide a detailed description of the waste problem',
      'Take photos if possible (feature coming soon)',
      'Submit your report and track its status',
      'You\'ll receive updates when the issue is addressed'
    ];
  }

  List<String> _getWasteSortingSteps() {
    return [
      'Organic Waste: Food scraps, garden waste, biodegradable materials',
      'Plastic: Bottles, bags, containers (clean and dry)',
      'Paper: Newspapers, cardboard, office paper (clean)',
      'Glass: Bottles, jars (remove caps and lids)',
      'Metal: Cans, aluminum foil, small metal items',
      'Electronic: Phones, computers, batteries (special handling)',
      'Hazardous: Chemicals, paint, medical waste (special disposal)',
      'Always clean containers before recycling',
      'When in doubt, check with local recycling centers'
    ];
  }

  List<String> _getRecyclingCenters() {
    return [
      'EcoRecycle Cameroon - Douala: Plastic & Metal recycling, +237 6XX XXX XXX',
      'Green Future Ltd - Yaoundé: Electronic waste specialist, +237 6XX XXX XXX',
      'Douala Recycling Co: Paper & Cardboard, +237 6XX XXX XXX',
      'Limbe Waste Management: General recycling, near Mile 1 Market',
      'Buea Green Center: Organic waste composting, University area',
      'Bamenda Eco Hub: Mixed recycling services, Commercial Avenue',
      'Contact centers before visiting to confirm operating hours',
      'Some centers offer pickup services for large quantities',
      'Bring sorted materials for faster processing'
    ];
  }

  List<String> _getProfileSetupSteps() {
    return [
      'Tap on your profile picture in the top section',
      'Add a clear profile photo for better recognition',
      'Update your username and contact information',
      'Select your role: User, Organization/Volunteer, or Government',
      'Enable notifications to stay updated on waste issues',
      'Set your location preferences for relevant reports',
      'Review privacy settings and data sharing options',
      'Save changes and verify your email if needed'
    ];
  }

  List<String> _getAppNavigationSteps() {
    return [
      'Home: View recent waste reports and schedule pickups',
      'Engage: Participate in community discussions and campaigns',
      'Profile: Manage your account and view your activity stats',
      'Post: Report new waste issues or browse existing requests',
      'Guide: Access tutorials and help documentation (you\'re here!)',
      'Use the search function to quickly find specific information',
      'Tap notification bell for updates on your reports',
      'Access settings through your profile page'
    ];
  }

  List<String> _getFirstTimeSteps() {
    return [
      'Welcome to Keep It Clean! Let\'s get you started',
      'Create your account with email or social login',
      'Complete your profile with basic information',
      'Take a tour of the main features and navigation',
      'Try reporting a waste issue in your area',
      'Explore community campaigns and beach cleanups',
      'Connect with local recycling centers and organizations',
      'Set up notifications for updates in your area',
      'Join the movement for a cleaner Cameroon!'
    ];
  }

  List<String> _getLimbeSchedule() {
    return [
      'Regular cleanups every Saturday at 6:00 AM',
      'Meet at Limbe Beach - Mile 1 main entrance',
      'Special cleanups during World Environment Day',
      'Monthly night cleanups during full moon',
      'Corporate group cleanups can be scheduled separately',
      'Rainy season adjustments (June-September)',
      'Check the Beach Cleanup tab in Volunteer Dashboard for updates',
      'Follow social media for weather-related changes'
    ];
  }

  List<String> _getBeachCleanupSupplies() {
    return [
      'Reusable gloves (provided if you don\'t have)',
      'Comfortable closed-toe shoes (no sandals)',
      'Sun hat and sunscreen for protection',
      'Reusable water bottle to stay hydrated',
      'Small snack for energy during cleanup',
      'Trash bags (usually provided by organizers)',
      'Camera to document before/after (optional)',
      'Positive attitude and team spirit!'
    ];
  }

  List<String> _getHazardousWasteGuide() {
    return [
      'Never handle hazardous waste without proper protection',
      'Common hazardous items: batteries, paint, chemicals, medical waste',
      'Contact local authorities for proper disposal methods',
      'Use designated hazardous waste collection centers',
      'Never mix different types of hazardous materials',
      'Store hazardous waste in original containers when possible',
      'Keep hazardous waste away from children and pets',
      'Follow local regulations for hazardous waste disposal'
    ];
  }

  List<String> _getSafetyGuidelines() {
    return [
      'Always wear protective gloves when handling waste',
      'Never touch sharp objects or hazardous materials directly',
      'Stay hydrated and take breaks in shade',
      'Work in pairs or groups, never alone',
      'Report any injuries to organizers immediately',
      'Avoid cleanup during heavy rain or storms',
      'Be careful of tides and slippery rocks',
      'Wash hands thoroughly after cleanup activities'
    ];
  }

  List<String> _getImpactMeasurement() {
    return [
      'Weight of waste collected (measured in kilograms)',
      'Types of waste categorized and counted',
      'Number of volunteers participated',
      'Area of beach cleaned (measured in meters)',
      'Before and after photos for visual impact',
      'CO2 emissions prevented through recycling',
      'Estimated marine life protected',
      'Community engagement and awareness raised'
    ];
  }

  List<String> _getCampaignCreationSteps() {
    return [
      'Access Volunteer Dashboard through your profile',
      'Tap the "New Campaign" floating action button',
      'Enter campaign title and detailed description',
      'Set location, date, and expected duration',
      'Define goals and expected outcomes',
      'Set volunteer requirements and skills needed',
      'Add safety guidelines and what to bring',
      'Publish campaign and start recruiting volunteers',
      'Monitor progress and update participants regularly'
    ];
  }

  List<String> _getVolunteerManagementSteps() {
    return [
      'Create clear volunteer roles and responsibilities',
      'Use the Volunteers tab to track participant information',
      'Send regular updates about campaign progress',
      'Provide training materials and safety briefings',
      'Recognize and appreciate volunteer contributions',
      'Collect feedback after each campaign',
      'Build a community of regular volunteers',
      'Partner with schools and organizations for recruitment'
    ];
  }

  List<String> _getPartnershipSteps() {
    return [
      'Identify local recycling companies and waste management firms',
      'Reach out with partnership proposals and mutual benefits',
      'Establish clear agreements on waste collection and processing',
      'Coordinate pickup schedules and logistics',
      'Track and report recycling outcomes together',
      'Explore funding opportunities for larger campaigns',
      'Share success stories and impact data',
      'Build long-term relationships for sustainable impact'
    ];
  }

  List<String> _getImpactTrackingSteps() {
    return [
      'Use the Impact tab in Volunteer Dashboard',
      'Record waste collected by type and weight',
      'Track volunteer hours and participation',
      'Calculate environmental benefits (CO2 saved, trees equivalent)',
      'Document before/after photos and videos',
      'Survey community satisfaction and awareness',
      'Share monthly impact reports with stakeholders',
      'Use data to improve future campaigns'
    ];
  }

  List<String> _getDashboardOverview() {
    return [
      'Access Hysacam Dashboard through your profile',
      'View waste reports organized by location',
      'Monitor patrol schedules and route efficiency',
      'Track completion rates and response times',
      'Analyze waste patterns and hotspot areas',
      'Generate reports for management and planning',
      'Coordinate with field teams and supervisors',
      'Update status of completed waste collections'
    ];
  }

  List<String> _getPatrolScheduling() {
    return [
      'Use the Patrol Schedule tab to plan routes',
      'Add new patrol schedules with location and time',
      'Assign teams to specific areas and routes',
      'Consider traffic patterns and peak waste times',
      'Update schedules based on citizen reports',
      'Track fuel efficiency and vehicle maintenance',
      'Coordinate with other government departments',
      'Adjust schedules for holidays and special events'
    ];
  }

  List<String> _getDataAnalysis() {
    return [
      'Review waste collection patterns by area and time',
      'Identify recurring problem locations',
      'Analyze seasonal variations in waste generation',
      'Track citizen engagement and report quality',
      'Monitor response times and efficiency metrics',
      'Generate insights for policy and planning decisions',
      'Share data with environmental agencies',
      'Use trends to allocate resources effectively'
    ];
  }

  List<String> _getPublicEngagement() {
    return [
      'Respond promptly to citizen waste reports',
      'Provide updates on cleanup progress',
      'Organize community awareness campaigns',
      'Partner with schools for environmental education',
      'Use social media to share success stories',
      'Encourage citizen participation in cleanups',
      'Recognize active community members',
      'Gather feedback for service improvement'
    ];
  }

  List<String> _getCommonIssues() {
    return [
      'Q: My report isn\'t showing up - A: Check your internet connection and try refreshing',
      'Q: How do I edit my profile? - A: Go to Profile > Edit Profile',
      'Q: Can\'t upload photos - A: Feature coming soon, use description for now',
      'Q: Wrong location selected - A: Double-tap the location field to change',
      'Q: Not receiving notifications - A: Check app permissions in device settings',
      'Q: How to delete a report? - A: Contact support, reports can\'t be deleted by users',
      'Q: App crashes frequently - A: Update to latest version or restart device',
      'Q: Forgot password - A: Use "Forgot Password" on sign-in page'
    ];
  }

  List<String> _getContactInfo() {
    return [
      'Email Support: support@keepitclean.cm',
      'Phone: +237 6XX XXX XXX (Mon-Fri, 8AM-5PM)',
      'WhatsApp: +237 6XX XXX XXX (Quick responses)',
      'Office: Douala, Cameroon (by appointment)',
      'Social Media: @KeepItCleanCM on all platforms',
      'Emergency waste issues: Contact local authorities',
      'Bug reports: Use in-app feedback feature',
      'Partnership inquiries: partnerships@keepitclean.cm'
    ];
  }

  List<String> _getUpdateInfo() {
    return [
      'Version 2.1: Added volunteer dashboard and beach cleanup features',
      'Version 2.0: Introduced role-based dashboards for organizations',
      'Version 1.9: Enhanced profile management and statistics',
      'Version 1.8: Added Hysacam government dashboard',
      'Version 1.7: Improved navigation and user interface',
      'Version 1.6: Added social login options',
      'Version 1.5: Enhanced waste reporting with categories',
      'Check app store for latest updates and new features'
    ];
  }

  List<String> _getPrivacyInfo() {
    return [
      'We collect only necessary information for waste management',
      'Location data is used only for relevant waste reports',
      'Personal information is never shared with third parties',
      'You can delete your account and data at any time',
      'All data is encrypted and stored securely',
      'We comply with Cameroon data protection regulations',
      'Cookies are used only for app functionality',
      'Read full privacy policy at: keepitclean.cm/privacy'
    ];
  }

  List<String> _getCompostingSteps() {
    return [
      'Collect organic waste: fruit peels, vegetable scraps, coffee grounds',
      'Avoid meat, dairy, and oily foods in compost',
      'Layer green materials (nitrogen) with brown materials (carbon)',
      'Keep compost moist but not waterlogged',
      'Turn the pile every 2-3 weeks for aeration',
      'Compost is ready in 3-6 months when dark and crumbly',
      'Use finished compost in gardens and potted plants',
      'Start small with a simple bin or pile in your yard'
    ];
  }

  List<String> _getPlasticReductionTips() {
    return [
      'Use reusable shopping bags instead of plastic bags',
      'Carry a reusable water bottle and coffee cup',
      'Choose products with minimal plastic packaging',
      'Buy in bulk to reduce individual packaging',
      'Use glass or metal containers for food storage',
      'Avoid single-use plastic utensils and straws',
      'Support businesses that use eco-friendly packaging',
      'Repair and reuse plastic items when possible'
    ];
  }
}

class GuideItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> content;

  GuideItem(this.title, this.subtitle, this.icon, this.content);
}