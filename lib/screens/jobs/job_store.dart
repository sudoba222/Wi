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
