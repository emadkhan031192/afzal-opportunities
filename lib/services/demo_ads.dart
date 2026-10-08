import '../core/constants/app_constants.dart';
import '../models/advertisement.dart';

// DEMO DATA — only used when Firebase is not configured.
// See lib/services/firebase_config.dart. These advertisements are rebuilt
// relative to the current date so deadlines always look realistic.

/// Bundled sample advertisements shown when Firebase is not configured.
class DemoAds {
  const DemoAds._();

  /// Fresh demo advertisements on every access so deadlines stay current.
  static List<Advertisement> get ads => _buildAds();

  static Advertisement? byId(String id) {
    for (final ad in ads) {
      if (ad.id == id) {
        return ad;
      }
    }
    return null;
  }

  /// Date-only PKT date [daysFromToday] days from today.
  static DateTime _pktDate(int daysFromToday) {
    final pkt = DateTime.now().toUtc().add(const Duration(hours: 5));
    return DateTime(pkt.year, pkt.month, pkt.day)
        .add(Duration(days: daysFromToday));
  }

  static DateTime _hoursAgo(int hours) {
    return DateTime.now().toUtc().subtract(Duration(hours: hours));
  }

  static List<Advertisement> _buildAds() {
    return <Advertisement>[
      Advertisement(
        id: 'demo-lhv-2026',
        title: 'Lady Health Visitor (LHV) Recruitment 2026',
        organization: 'Health Department, Khyber Pakhtunkhwa',
        category: 'jobs',
        description:
            'The Health Department, Khyber Pakhtunkhwa invites applications '
            'from eligible female candidates for Lady Health Visitor positions '
            'in Basic Health Units across the province. Candidates must hold '
            'a recognized LHV diploma. Quota for minorities and persons with '
            'disabilities will be observed as per government policy.',
        location: 'Peshawar, Khyber Pakhtunkhwa',
        sourceUrl: 'https://healthkp.gov.pk',
        applicationUrl: 'https://healthkp.gov.pk',
        publishedAt: _hoursAgo(5),
        lastDate: _pktDate(12),
        status: AppConstants.statusPublished,
        isFeatured: true,
      ),
      Advertisement(
        id: 'demo-pst-2026',
        title: 'Primary School Teacher (PST) Jobs 2026',
        organization: 'Elementary & Secondary Education Department, KP',
        category: 'jobs',
        description:
            'The Elementary & Secondary Education Department has announced '
            'Primary School Teacher (PST) vacancies for various districts. '
            'Applicants must have at least an Intermediate qualification with '
            'PTC/CT. Applications are submitted through the official testing '
            'service portal before the last date.',
        location: 'Khyber Pakhtunkhwa',
        publishedAt: _hoursAgo(50),
        lastDate: _pktDate(1),
        status: AppConstants.statusPublished,
      ),
      Advertisement(
        id: 'demo-ehsaas-2026',
        title: 'Ehsaas Undergraduate Scholarship 2026',
        organization: 'Higher Education Commission',
        category: 'scholarships',
        description:
            'Need-based undergraduate scholarships for students enrolled in '
            'public-sector universities. The scholarship covers the full '
            'tuition fee plus a monthly stipend. Applicants must have secured '
            'admission on merit and demonstrate financial need.',
        location: 'All Pakistan',
        publishedAt: _hoursAgo(150),
        lastDate: _pktDate(5),
        status: AppConstants.statusPublished,
      ),
      Advertisement(
        id: 'demo-uop-fall-2026',
        title: 'University of Peshawar — Fall Admissions 2026',
        organization: 'University of Peshawar',
        category: 'admissions',
        description:
            'Admissions are open for BS, MA/MSc and MS/MPhil programs for '
            'the Fall 2026 session. Entry tests and merit lists will be '
            'announced on the university website. Hostel facility is '
            'available on merit.',
        location: 'Peshawar, Khyber Pakhtunkhwa',
        sourceUrl: 'https://uop.edu.pk',
        publishedAt: _hoursAgo(220),
        lastDate: _pktDate(20),
        status: AppConstants.statusPublished,
      ),
      Advertisement(
        id: 'demo-courses',
        title: 'Free Computer Courses at Afzal E Services',
        organization: 'Afzal E Services',
        category: 'other',
        description:
            'Afzal E Services is offering free basic computer courses '
            'including MS Office, internet skills and online-apply guidance '
            'for students and job seekers in Mardan. Limited seats per batch '
            '— visit our office to register.',
        location: 'Mardan, Khyber Pakhtunkhwa',
        sourceUrl: 'https://whatsapp.com/channel/0029Va8EBlpLI8YRkHbALM1b',
        publishedAt: _hoursAgo(26),
        lastDate: null,
        status: AppConstants.statusPublished,
      ),
      Advertisement(
        id: 'demo-constable-2025',
        title: 'Police Constable Recruitment 2025',
        organization: 'Khyber Pakhtunkhwa Police',
        category: 'jobs',
        description:
            'Recruitment of Police Constables (BPS-07) in Khyber Pakhtunkhwa '
            'Police. Physical and written tests were conducted through the '
            'official testing service. This advertisement is kept for archive '
            'purposes only.',
        location: 'Khyber Pakhtunkhwa',
        publishedAt: _hoursAgo(960),
        lastDate: _pktDate(-10),
        status: AppConstants.statusPublished,
      ),
    ];
  }
}
