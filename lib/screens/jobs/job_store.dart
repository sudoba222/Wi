// ignore_for_file: deprecated_member_use

class AppEntry {
  final String jobTitle;
  final String company;
  final String logo;
  final String salary;
  final String jobType;
  final int colorValue;
  final bool easyApply;
  final String appliedAt;
  String status;

  AppEntry({
    required this.jobTitle,
    required this.company,
    required this.logo,
    required this.salary,
    required this.jobType,
    required this.colorValue,
    required this.easyApply,
    required this.appliedAt,
    required this.status,
  });
}

class Applicant {
  final String id;
  final String name;
  final String currentRole;
  final String avatarInitial;
  final int avatarColor;
  final String appliedMethod;
  String status;
  final String appliedAt;
  final String experience;
  final List<String> skills;

  Applicant({
    required this.id,
    required this.name,
    required this.currentRole,
    required this.avatarInitial,
    required this.avatarColor,
    required this.appliedMethod,
    required this.status,
    required this.appliedAt,
    required this.experience,
    required this.skills,
  });
}

class JobPosting {
  final String id;
  String title;
  String category;
  String type;
  String workStyle;
  String location;
  String salaryMin;
  String salaryMax;
  String description;
  List<String> requirements;
  bool easyApplyEnabled;
  String status;
  int viewCount;
  final List<Applicant> applicants;
  final DateTime postedAt;

  JobPosting({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.workStyle,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    required this.description,
    required this.requirements,
    required this.easyApplyEnabled,
    required this.status,
    required this.viewCount,
    required this.applicants,
    required this.postedAt,
  });

  int get applicantCount => applicants.length;
  int get newCount => applicants.where((a) => a.status == 'new').length;
  int get reviewingCount => applicants.where((a) => a.status == 'reviewing').length;
  int get interviewCount => applicants.where((a) => a.status == 'interview').length;
  int get offerCount => applicants.where((a) => a.status == 'offer').length;
  int get rejectedCount => applicants.where((a) => a.status == 'rejected').length;
}

// ─── Job Seeker Profile ───────────────────────────────────────────────────────
// Collected during onboarding; stored in-session. Used to pre-fill Easy Apply.

class JobSeekerProfile {
  String phone;
  String location;
  String summary;
  String linkedIn;
  String portfolioUrl;
  String cvFileName;
  String cvUploadedAt;
  bool cvUploaded;
  bool setupComplete;

  JobSeekerProfile({
    this.phone = '',
    this.location = '',
    this.summary = '',
    this.linkedIn = '',
    this.portfolioUrl = '',
    this.cvFileName = '',
    this.cvUploadedAt = '',
    this.cvUploaded = false,
    this.setupComplete = false,
  });

  int get completionPct {
    int pts = 0;
    if (phone.isNotEmpty) pts += 25;
    if (location.isNotEmpty) pts += 20;
    if (summary.isNotEmpty) pts += 25;
    if (cvUploaded) pts += 30;
    return pts;
  }
}

// ─── Company Profile ─────────────────────────────────────────────────────────
// Collected during employer onboarding; editable afterwards.

class CompanyProfile {
  String name;
  String industry;
  String size;       // '1–10', '11–50', '51–200', '201–500', '500+'
  String location;
  String website;
  String description;
  int logoColor;
  String logoInitial;
  bool setupComplete;

  CompanyProfile({
    this.name = '',
    this.industry = '',
    this.size = '',
    this.location = '',
    this.website = '',
    this.description = '',
    this.logoColor = 0xFF6C5CE7,
    this.logoInitial = '',
    this.setupComplete = false,
  });

  int get completionPct {
    int pts = 0;
    if (name.isNotEmpty) pts += 20;
    if (industry.isNotEmpty) pts += 20;
    if (size.isNotEmpty) pts += 15;
    if (location.isNotEmpty) pts += 15;
    if (website.isNotEmpty) pts += 10;
    if (description.isNotEmpty) pts += 20;
    return pts;
  }
}

// ─── Central Store ───────────────────────────────────────────────────────────

class JobsStore {
  static final JobSeekerProfile seekerProfile = JobSeekerProfile();
  static final CompanyProfile companyProfile = CompanyProfile(
    name: '',
    logoInitial: '',
    logoColor: 0xFF6C5CE7,
  );

  // Keep companyName in sync with companyProfile.name for legacy refs.
  static String get companyName => companyProfile.name.isNotEmpty ? companyProfile.name : 'Your Company';
  static String get companyIndustry => companyProfile.industry.isNotEmpty ? companyProfile.industry : 'Technology';

  static final List<AppEntry> seekerApplications = [];

  static final List<Map<String, dynamic>> jobBoard = [
    {
      'title': 'Flutter Developer',
      'company': 'Alif.tj',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$800–1,200/mo',
      'posted': '2h ago',
      'logo': 'A',
      'color': 0xFF6C5CE7,
      'isRemote': true,
      'saved': false,
      'category': 'Software Dev',
      'workStyle': 'remote',
      'description':
          'Alif.tj is Tajikistan\'s leading fintech company, serving over 2 million customers '
          'with mobile banking, lending, and e-commerce solutions. We are looking for a '
          'skilled Flutter developer to join our mobile engineering team and help us build '
          'the next generation of our flagship app.\n\n'
          'You will collaborate with product designers and backend engineers to ship polished, '
          'performant features to both iOS and Android simultaneously. Our stack is Firebase + '
          'custom REST APIs, and we ship fast — at least two production releases per month.',
      'requirements': [
        '2+ years Flutter / Dart experience in production apps',
        'Proficiency with Firebase (Auth, Firestore, Storage)',
        'State management mastery: Provider, Bloc, or Riverpod',
        'Clean architecture knowledge (feature-first or layered)',
        'Experience integrating REST and WebSocket APIs',
        'Published apps on Play Store or App Store is a strong plus',
      ],
      'benefits': [
        'Fully remote — work from anywhere in Tajikistan',
        'Competitive salary reviewed every 6 months',
        'Annual learning budget: \$500 for courses and conferences',
        'Health insurance for you and your family',
        '25 days paid vacation + public holidays',
      ],
    },
    {
      'title': 'UI/UX Designer',
      'company': 'DushanbeIT',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$600–900/mo',
      'posted': '5h ago',
      'logo': 'D',
      'color': 0xFFBC96E6,
      'isRemote': false,
      'saved': false,
      'category': 'Design',
      'workStyle': 'onsite',
      'description':
          'DushanbeIT is a fast-growing product studio building SaaS tools and marketplaces '
          'for Central Asian businesses. We are searching for a product-minded UI/UX designer '
          'who takes pride in the details.\n\n'
          'You will own end-to-end design for two products: a B2B logistics platform and a '
          'consumer marketplace. You\'ll run discovery sessions, produce wireframes and '
          'high-fidelity Figma prototypes, and work closely with front-end engineers during '
          'implementation to ensure pixel-perfect delivery.',
      'requirements': [
        'Figma mastery — components, auto-layout, and variables',
        'Mobile-first design experience for iOS and Android',
        'Strong portfolio with at least 2 full case studies',
        'Experience conducting user interviews and usability tests',
        'Working knowledge of HTML/CSS to communicate with devs',
        'Prior experience with design systems is a plus',
      ],
      'benefits': [
        'Modern office in the heart of Dushanbe',
        'Latest MacBook Pro and external display',
        'Adobe CC and Figma Professional licenses',
        'Bi-annual team retreats',
        'Flexible working hours (core hours 10:00–16:00)',
      ],
    },
    {
      'title': 'Marketing Manager',
      'company': 'TajTelecom',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$700–1,000/mo',
      'posted': '1d ago',
      'logo': 'T',
      'color': 0xFF00B894,
      'isRemote': false,
      'saved': true,
      'category': 'Marketing',
      'workStyle': 'onsite',
      'description':
          'TajTelecom is the national telecommunications provider connecting over 8 million '
          'people across Tajikistan. As Marketing Manager you will lead a team of five '
          'specialists driving brand awareness, subscriber growth, and retention across '
          'digital and traditional channels.\n\n'
          'This is a senior individual-contributor role with a clear path to Head of Marketing '
          'within 18 months.',
      'requirements': [
        '4+ years in B2C marketing, ideally in telecoms or consumer tech',
        'Hands-on experience with Google Ads, Meta Ads, and programmatic DSPs',
        'Strong analytical skills — comfortable in Google Analytics and Power BI',
        'Experience managing creative agencies and production timelines',
        'Fluent in Tajik and Russian; English is a plus',
      ],
      'benefits': [
        'Generous bonus tied to subscriber growth KPIs',
        'Free TajTelecom unlimited plan for you and your family',
        'Corporate car allowance',
        'Leadership training programme',
        'Paid professional certifications (Google, Meta)',
      ],
    },
    {
      'title': 'Financial Analyst',
      'company': 'Bank Eskhata',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$900–1,400/mo',
      'posted': '2d ago',
      'logo': 'B',
      'color': 0xFFFFD166,
      'isRemote': false,
      'saved': false,
      'category': 'Finance',
      'workStyle': 'onsite',
      'description':
          'Bank Eskhata is one of Tajikistan\'s top-tier commercial banks, offering retail, '
          'SME, and corporate financial products. The Financial Analyst role sits within the '
          'Corporate Finance team and focuses on credit analysis, financial modelling, and '
          'investment appraisal for loan portfolios up to \$5M.\n\n'
          'You will prepare detailed credit memos, support relationship managers with client '
          'due diligence, and contribute to the bank\'s quarterly financial reporting.',
      'requirements': [
        'Bachelor\'s degree in Finance, Economics, or Accounting',
        '2+ years financial analysis experience in banking or consulting',
        'Advanced Excel and financial modelling skills (DCF, LBO basics)',
        'Familiarity with IFRS accounting standards',
        'CFA Level I is a strong advantage',
        'Fluency in Russian; English is beneficial',
      ],
      'benefits': [
        'Competitive salary plus performance bonus up to 30%',
        'Subsidised mortgage rate for bank employees',
        'Comprehensive health and dental insurance',
        'Sponsored CFA or ACCA study programme',
        '20 days annual leave',
      ],
    },
    {
      'title': 'Backend Engineer',
      'company': 'iPayments',
      'location': 'Remote',
      'type': 'Contract',
      'salary': '\$1,000–1,800/mo',
      'posted': '3d ago',
      'logo': 'i',
      'color': 0xFF210B2C,
      'isRemote': true,
      'saved': false,
      'category': 'Software Dev',
      'workStyle': 'remote',
      'description':
          'iPayments is building a modern payment infrastructure for Central Asia, enabling '
          'merchants and consumers to transact via cards, wallets, and BNPL. We are looking '
          'for a senior backend contract engineer to help us scale our API platform to handle '
          '100k+ transactions per day.\n\n'
          'This is a 6-month contract with strong likelihood of extension or conversion to a '
          'permanent role. You will work autonomously, own several service areas, and report '
          'directly to the CTO.',
      'requirements': [
        '3+ years backend experience in Python (FastAPI) or Node.js (Express)',
        'Strong PostgreSQL skills — query optimisation, indexing, migrations',
        'Experience designing RESTful and WebSocket APIs at scale',
        'Redis for caching and rate limiting',
        'Docker and CI/CD pipelines (GitHub Actions or GitLab CI)',
        'Basic knowledge of PCI-DSS compliance is a plus',
      ],
      'benefits': [
        '100% remote — async-first culture',
        'Competitive hourly rate paid in USD',
        'Flexible hours — deliverable-focused, not hours-tracked',
        'Modern tooling: linear, Notion, Slack, GitHub',
        'Option to extend or convert to a permanent position',
      ],
    },
    {
      'title': 'Content Creator',
      'company': 'MediaTJ',
      'location': 'Dushanbe, TJ',
      'type': 'Part-time',
      'salary': '\$400–600/mo',
      'posted': '4d ago',
      'logo': 'M',
      'color': 0xFFE17055,
      'isRemote': true,
      'saved': false,
      'category': 'Marketing',
      'workStyle': 'remote',
      'description':
          'MediaTJ is the largest digital media group in Tajikistan, operating news portals, '
          'YouTube channels, and Instagram pages with a combined following of 3.5 million. '
          'We need a creative Content Creator to produce engaging short-form video and '
          'written content for our social channels.\n\n'
          'This is a part-time remote role averaging 20 hours per week, ideal for a creative '
          'professional looking to build a portfolio while maintaining flexibility.',
      'requirements': [
        '1+ year experience creating content for Instagram or TikTok',
        'Video editing skills (CapCut, Adobe Premiere, or DaVinci)',
        'Strong written Tajik and Russian; English is a bonus',
        'Understanding of social media algorithms and best practices',
        'Ability to generate and pitch original content ideas weekly',
      ],
      'benefits': [
        'Work from anywhere, fully remote',
        'Creative freedom — we trust your ideas',
        'Equipment allowance for camera and accessories',
        'Growing team with mentorship from senior editors',
      ],
    },
    {
      'title': 'Sales Representative',
      'company': 'Somoni Motors',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$500–800/mo',
      'posted': '5d ago',
      'logo': 'S',
      'color': 0xFF74B9FF,
      'isRemote': false,
      'saved': false,
      'category': 'Sales',
      'workStyle': 'onsite',
      'description':
          'Somoni Motors is the authorised dealer for leading automotive brands in Tajikistan, '
          'with three showrooms in Dushanbe and Khujand. We are expanding our sales team and '
          'looking for a motivated Sales Representative to help customers find their perfect '
          'vehicle.\n\n'
          'You will manage inbound leads, conduct showroom presentations, arrange test drives, '
          'and guide customers through the financing and delivery process.',
      'requirements': [
        '1+ year sales or customer-facing experience (automotive is a plus)',
        'Excellent interpersonal and negotiation skills',
        'Fluent in Tajik and Russian',
        'Valid driver\'s licence',
        'Comfortable using CRM software',
        'Target-driven with a positive, resilient attitude',
      ],
      'benefits': [
        'Uncapped commission — top performers earn \$1,500+/mo',
        'Company vehicle for business use',
        'Product training provided by brand manufacturers',
        'Health insurance',
        'Regular team incentives and prizes',
      ],
    },
    {
      'title': 'Product Manager',
      'company': 'TechHub TJ',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$1,200–2,000/mo',
      'posted': '1w ago',
      'logo': 'T',
      'color': 0xFFFF7675,
      'isRemote': false,
      'saved': false,
      'category': 'Operations',
      'workStyle': 'onsite',
      'description':
          'TechHub TJ is a startup accelerator and co-working space that has launched 14 '
          'startups in the past three years. We are spinning up a new SaaS product for the '
          'HR/payroll vertical and need an experienced Product Manager to lead it from zero '
          'to one.\n\n'
          'You will define the product vision, own the roadmap, work daily with engineering '
          'and design, and talk to customers every week. This is a high-ownership, '
          'high-impact role.',
      'requirements': [
        '3+ years PM experience in a B2B SaaS environment',
        'Strong track record shipping products users love',
        'Excellent user-story writing and backlog management skills',
        'Comfortable with SQL and basic data analysis to measure outcomes',
        'Experience running A/B tests and interpreting results',
        'Exceptional communication skills in English and Russian',
      ],
      'benefits': [
        'Equity participation in the product you build',
        'Co-working access at TechHub TJ campus',
        'Annual conference and travel budget',
        'Private health insurance',
        'Flexible PTO policy',
      ],
    },
    {
      'title': 'Data Analyst',
      'company': 'Alif Academy',
      'location': 'Remote',
      'type': 'Full-time',
      'salary': '\$700–1,100/mo',
      'posted': '2d ago',
      'logo': 'A',
      'color': 0xFF0984E3,
      'isRemote': true,
      'saved': false,
      'category': 'Finance',
      'workStyle': 'remote',
      'description':
          'Alif Academy is an online education platform with 200,000+ active learners across '
          'Central Asia. We are hiring a Data Analyst to turn our rich learner behaviour data '
          'into actionable insights that drive course completion rates, retention, and revenue.\n\n'
          'You will build dashboards, run ad-hoc analyses, and partner with the product and '
          'marketing teams on data-informed decisions.',
      'requirements': [
        '2+ years data analysis experience',
        'Advanced SQL — window functions, CTEs, query optimisation',
        'Proficiency in Python (pandas, matplotlib) or R',
        'Experience with BI tools: Metabase, Tableau, or Looker',
        'Strong statistical intuition — A/B testing, cohort analysis',
        'Experience with a cloud data warehouse (BigQuery, Redshift, or Snowflake) is a plus',
      ],
      'benefits': [
        'Fully remote with flexible hours',
        'Free access to all Alif Academy courses',
        'Quarterly data team offsites',
        'Paid subscriptions to data tools and learning platforms',
        'Annual salary review',
      ],
    },
    {
      'title': 'HR Manager',
      'company': 'Orienbank',
      'location': 'Dushanbe, TJ',
      'type': 'Full-time',
      'salary': '\$600–850/mo',
      'posted': '3d ago',
      'logo': 'O',
      'color': 0xFFE84393,
      'isRemote': false,
      'saved': false,
      'category': 'HR',
      'workStyle': 'onsite',
      'description':
          'Orienbank is one of the fastest-growing retail banks in Tajikistan with 1,200 '
          'employees across 40 branches. We are looking for an experienced HR Manager to '
          'lead talent acquisition and employee development for our Dushanbe headquarters '
          'team of 300 people.\n\n'
          'You will manage the full recruitment lifecycle, run onboarding programmes, '
          'coordinate performance review cycles, and champion a positive culture that '
          'attracts and retains top talent.',
      'requirements': [
        '3+ years HR management experience, preferably in financial services',
        'Proven track record recruiting at scale (100+ hires per year)',
        'Strong knowledge of Tajik labour law',
        'Experience designing and running performance management systems',
        'CIPD or SHRM certification is a plus',
        'Excellent communication in Tajik, Russian, and ideally English',
      ],
      'benefits': [
        'Competitive salary with annual review',
        'Subsidised canteen and on-site gym',
        'Professional HR certification support',
        'Internal promotion programme',
        'Comprehensive health insurance',
      ],
    },
  ];

  static final List<JobPosting> employerPostings = [
    JobPosting(
      id: '1',
      title: 'Flutter Developer',
      category: 'Software Dev',
      type: 'Full-time',
      workStyle: 'remote',
      location: 'Remote',
      salaryMin: '800',
      salaryMax: '1200',
      description:
          'We are looking for an experienced Flutter developer to build high-quality '
          'cross-platform mobile applications. You will work closely with our product and '
          'design teams to deliver exceptional user experiences.',
      requirements: [
        '2+ years Flutter / Dart experience',
        'Firebase or REST API integration',
        'State management (Provider / Bloc / Riverpod)',
        'Clean architecture knowledge',
        'Published apps on Play Store or App Store (plus)',
      ],
      easyApplyEnabled: true,
      status: 'active',
      viewCount: 124,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      applicants: [
        Applicant(
          id: 'a1',
          name: 'Alisher Nazarov',
          currentRole: 'Mid Flutter Developer',
          avatarInitial: 'A',
          avatarColor: 0xFF6C5CE7,
          appliedMethod: 'easy',
          status: 'new',
          appliedAt: '2h ago',
          experience: '3 years',
          skills: ['Flutter', 'Dart', 'Firebase', 'Provider'],
        ),
        Applicant(
          id: 'a2',
          name: 'Zarina Khodjaeva',
          currentRole: 'Junior Developer',
          avatarInitial: 'Z',
          avatarColor: 0xFFBC96E6,
          appliedMethod: 'cv',
          status: 'reviewing',
          appliedAt: '5h ago',
          experience: '1 year',
          skills: ['Flutter', 'Dart', 'REST APIs'],
        ),
        Applicant(
          id: 'a3',
          name: 'Rustam Toshmatov',
          currentRole: 'Senior Mobile Dev',
          avatarInitial: 'R',
          avatarColor: 0xFF00B894,
          appliedMethod: 'cv',
          status: 'interview',
          appliedAt: '1d ago',
          experience: '6 years',
          skills: ['Flutter', 'iOS', 'Android', 'Firebase', 'GraphQL'],
        ),
        Applicant(
          id: 'a4',
          name: 'Parviz Rakhimov',
          currentRole: 'Flutter Engineer',
          avatarInitial: 'P',
          avatarColor: 0xFFFFD166,
          appliedMethod: 'easy',
          status: 'new',
          appliedAt: '4h ago',
          experience: '4 years',
          skills: ['Flutter', 'GetX', 'GraphQL', 'CI/CD'],
        ),
        Applicant(
          id: 'a5',
          name: 'Shoira Yunusova',
          currentRole: 'Mobile Developer',
          avatarInitial: 'S',
          avatarColor: 0xFFE84393,
          appliedMethod: 'cv',
          status: 'offer',
          appliedAt: '3d ago',
          experience: '5 years',
          skills: ['Flutter', 'Dart', 'Firebase', 'Bloc'],
        ),
      ],
    ),
    JobPosting(
      id: '2',
      title: 'UI/UX Designer',
      category: 'Design',
      type: 'Full-time',
      workStyle: 'onsite',
      location: 'Dushanbe, TJ',
      salaryMin: '600',
      salaryMax: '900',
      description:
          'Looking for a creative UI/UX designer to craft beautiful and intuitive product '
          'experiences. You will own the entire design process from concept to pixel-perfect '
          'handoff, working with engineers to ensure quality implementation.',
      requirements: [
        'Figma & Adobe XD proficiency',
        'Mobile-first design experience (iOS + Android)',
        'Strong portfolio with case studies',
        'Basic understanding of dev constraints',
        'Experience with design systems',
      ],
      easyApplyEnabled: false,
      status: 'active',
      viewCount: 87,
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      applicants: [
        Applicant(
          id: 'b1',
          name: 'Malika Rahimova',
          currentRole: 'Product Designer',
          avatarInitial: 'M',
          avatarColor: 0xFFFF7675,
          appliedMethod: 'cv',
          status: 'new',
          appliedAt: '3h ago',
          experience: '4 years',
          skills: ['Figma', 'Adobe XD', 'Prototyping', 'User Research'],
        ),
        Applicant(
          id: 'b2',
          name: 'Doniyor Hamidov',
          currentRole: 'UI Designer',
          avatarInitial: 'D',
          avatarColor: 0xFFFFD166,
          appliedMethod: 'cv',
          status: 'interview',
          appliedAt: '2d ago',
          experience: '2 years',
          skills: ['Figma', 'Sketch', 'CSS', 'Illustrations'],
        ),
        Applicant(
          id: 'b3',
          name: 'Kamola Saidova',
          currentRole: 'Visual Designer',
          avatarInitial: 'K',
          avatarColor: 0xFF0984E3,
          appliedMethod: 'cv',
          status: 'reviewing',
          appliedAt: '1d ago',
          experience: '3 years',
          skills: ['Figma', 'Branding', 'Motion Design'],
        ),
      ],
    ),
    JobPosting(
      id: '3',
      title: 'Backend Engineer',
      category: 'Software Dev',
      type: 'Contract',
      workStyle: 'hybrid',
      location: 'Dushanbe, TJ',
      salaryMin: '1000',
      salaryMax: '1800',
      description:
          'Seeking a backend engineer to architect and build scalable APIs for our fintech '
          'platform. You will design server-side logic, database schemas, and third-party '
          'payment integrations.',
      requirements: [
        '3+ years backend experience',
        'Python (FastAPI) or Node.js (Express)',
        'PostgreSQL / Redis',
        'RESTful & WebSocket API design',
        'Docker / CI-CD experience',
      ],
      easyApplyEnabled: true,
      status: 'paused',
      viewCount: 56,
      postedAt: DateTime.now().subtract(const Duration(days: 10)),
      applicants: [],
    ),
  ];

  static int get totalApplicants =>
      employerPostings.fold(0, (s, p) => s + p.applicantCount);
  static int get activeListings =>
      employerPostings.where((p) => p.status == 'active').length;
  static int get totalViews =>
      employerPostings.fold(0, (s, p) => s + p.viewCount);
  static int get totalHires =>
      employerPostings.fold(0, (s, p) => s + p.offerCount);
}
