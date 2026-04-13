import 'package:flutter/material.dart';

enum AppLanguage { en, ru, tj }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _lang = AppLanguage.en;

  AppLanguage get lang => _lang;

  String get langLabel {
    switch (_lang) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ru:
        return 'Русский';
      case AppLanguage.tj:
        return 'Тоҷикӣ';
    }
  }

  void setLanguage(AppLanguage lang) {
    _lang = lang;
    notifyListeners();
  }

  String t(String key) => _strings[_lang]?[key] ?? _strings[AppLanguage.en]![key] ?? key;

  static const _strings = {
    AppLanguage.en: {
      'feed': 'Feed',
      'messages': 'Messages',
      'profile': 'Profile',
      'jobs': 'Jobs',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'helpSupport': 'Help & Support',
      'about': 'About Wi',
      'signOut': 'Sign Out',
      'search': 'Search Wi',
      'noPosts': 'No posts yet',
      'firstPost': 'Be the first to share something\nto Wi Tajikistan!',
      'noMessages': 'No messages yet',
      'startConversation': 'Start a conversation',
      // Notifications
      'notifications': 'Notifications',
      'markAllRead': 'Mark all read',
      'noNotifications': 'No notifications yet',
      'noNotificationsSub': 'When someone likes, comments\nor follows you, it will appear here.',
      // About
      'about': 'About Wi',
      'aboutTagline': 'Work Interconnected',
      'ourMission': 'Our Mission',
      'missionText': 'Wi Tajikistan is a professional networking platform built to connect the talented workforce of Tajikistan with opportunities, peers, and employers — all in one place.',
      'whatIsWi': 'What is Wi?',
      'whatIsWiText': 'Wi (Work Interconnected) is a career and professional community app designed for Tajikistan. Connect with professionals, find jobs, share your work, and grow your career.',
      'keyFeatures': 'Key Features',
      'featureJobs': 'Find Jobs',
      'featureNetwork': 'Network',
      'featureChat': 'Messaging',
      'featureFeed': 'Work Feed',
      'madeIn': 'Made with love in Tajikistan',
      // Help & Support
      'helpTitle': 'We\'re here to help',
      'helpSubtitle': 'Find answers or contact our support team',
      'faqTitle': 'Frequently Asked Questions',
      'contactUs': 'Contact Us',
      'contactEmail': 'Email Support',
      'contactTelegram': 'Telegram',
      'reportBug': 'Report a Bug',
      'reportBugSub': 'Help us improve the app',
      'faq1q': 'How do I create an account?',
      'faq1a': 'Tap "Sign Up" on the login screen, fill in your name, email, and password, then verify your email to get started.',
      'faq2q': 'How do I update my profile?',
      'faq2a': 'Go to your Profile page and tap the edit button. You can update your photo, job title, company, bio, education, and experience.',
      'faq3q': 'How do I post a job?',
      'faq3a': 'Navigate to the Jobs tab and tap the "Post a Job" button. Fill in the job details and publish it for others to see.',
      'faq4q': 'Can I message anyone on Wi?',
      'faq4a': 'Yes! You can start a conversation with any user by visiting their profile and tapping the Message button.',
      'faq5q': 'How do I change the app language?',
      'faq5a': 'Open the side menu (hamburger icon) and scroll to the Language section. Choose between English, Russian, or Tajik.',
    },
    AppLanguage.ru: {
      'feed': 'Лента',
      'messages': 'Сообщения',
      'profile': 'Профиль',
      'jobs': 'Вакансии',
      'settings': 'Настройки',
      'darkMode': 'Тёмная тема',
      'language': 'Язык',
      'helpSupport': 'Помощь',
      'about': 'О Wi',
      'signOut': 'Выйти',
      'search': 'Поиск в Wi',
      'noPosts': 'Нет публикаций',
      'firstPost': 'Будьте первым, кто поделится\nчем-то в Wi Таджикистан!',
      'noMessages': 'Нет сообщений',
      'startConversation': 'Начать разговор',
      // Notifications
      'notifications': 'Уведомления',
      'markAllRead': 'Отметить все',
      'noNotifications': 'Уведомлений пока нет',
      'noNotificationsSub': 'Когда кто-то лайкнет, прокомментирует\nили подпишется — это появится здесь.',
      // About
      'about': 'О Wi',
      'aboutTagline': 'Работа. Связь. Рост.',
      'ourMission': 'Наша миссия',
      'missionText': 'Wi Таджикистан — профессиональная платформа для объединения специалистов Таджикистана с возможностями, коллегами и работодателями.',
      'whatIsWi': 'Что такое Wi?',
      'whatIsWiText': 'Wi (Work Interconnected) — карьерное приложение для Таджикистана. Находите работу, общайтесь с профессионалами и развивайте карьеру.',
      'keyFeatures': 'Возможности',
      'featureJobs': 'Вакансии',
      'featureNetwork': 'Сеть',
      'featureChat': 'Сообщения',
      'featureFeed': 'Лента',
      'madeIn': 'Сделано с любовью в Таджикистане',
      // Help & Support
      'helpTitle': 'Мы готовы помочь',
      'helpSubtitle': 'Найдите ответы или свяжитесь с поддержкой',
      'faqTitle': 'Часто задаваемые вопросы',
      'contactUs': 'Связаться с нами',
      'contactEmail': 'Email поддержка',
      'contactTelegram': 'Telegram',
      'reportBug': 'Сообщить об ошибке',
      'reportBugSub': 'Помогите нам улучшить приложение',
      'faq1q': 'Как создать аккаунт?',
      'faq1a': 'Нажмите «Регистрация», заполните имя, email и пароль, затем подтвердите email.',
      'faq2q': 'Как обновить профиль?',
      'faq2a': 'Перейдите в раздел «Профиль» и нажмите кнопку редактирования.',
      'faq3q': 'Как опубликовать вакансию?',
      'faq3a': 'Перейдите на вкладку «Вакансии» и нажмите «Опубликовать вакансию».',
      'faq4q': 'Могу ли я писать любому пользователю?',
      'faq4a': 'Да! Зайдите в профиль пользователя и нажмите кнопку «Сообщение».',
      'faq5q': 'Как изменить язык приложения?',
      'faq5a': 'Откройте боковое меню и найдите раздел «Язык». Выберите один из трёх языков.',
    },
    AppLanguage.tj: {
      'feed': 'Лента',
      'messages': 'Паёмҳо',
      'profile': 'Профил',
      'jobs': 'Корҳо',
      'settings': 'Танзимот',
      'darkMode': 'Мавзӯи торик',
      'language': 'Забон',
      'helpSupport': 'Кӯмак',
      'about': 'Дар бораи Wi',
      'signOut': 'Баромадан',
      'search': 'Ҷустуҷӯ дар Wi',
      'noPosts': 'Паёмҳо нест',
      'firstPost': 'Аввалин шавед,\nки дар Wi Тоҷикистон мубодила кунед!',
      'noMessages': 'Паёмҳо нест',
      'startConversation': 'Сӯҳбат оғоз кунед',
      // Notifications
      'notifications': 'Огоҳиномаҳо',
      'markAllRead': 'Ҳама хонда шуд',
      'noNotifications': 'Огоҳиномаҳо нест',
      'noNotificationsSub': 'Вақте касе лайк, шарҳ ё обуна кунад\nинҷо намоиш дода мешавад.',
      // About
      'about': 'Дар бораи Wi',
      'aboutTagline': 'Кор. Иртибот. Рушд.',
      'ourMission': 'Рисолати мо',
      'missionText': 'Wi Тоҷикистон платформаи касбии барои пайваст кардани мутахассисони Тоҷикистон бо имкониятҳо, ҳамкасбон ва корфармоён мебошад.',
      'whatIsWi': 'Wi чист?',
      'whatIsWiText': 'Wi (Work Interconnected) — барномаи касбӣ барои Тоҷикистон. Кор ёбед, бо мутахассисон муошират кунед ва касби худро рушд диҳед.',
      'keyFeatures': 'Имкониятҳо',
      'featureJobs': 'Ёфтани кор',
      'featureNetwork': 'Шабака',
      'featureChat': 'Паёмҳо',
      'featureFeed': 'Лента',
      'madeIn': 'Бо муҳаббат дар Тоҷикистон сохта шуд',
      // Help & Support
      'helpTitle': 'Мо омодаем кӯмак кунем',
      'helpSubtitle': 'Ҷавобҳо ёбед ё бо дастгирӣ тамос гиред',
      'faqTitle': 'Саволҳои зуд-зуд додашаванда',
      'contactUs': 'Тамос бо мо',
      'contactEmail': 'Дастгирии Email',
      'contactTelegram': 'Telegram',
      'reportBug': 'Хатоӣ гузориш диҳед',
      'reportBugSub': 'Ба беҳтар шудани барнома кӯмак кунед',
      'faq1q': 'Чӣ тавр аккаунт сохтан мумкин?',
      'faq1a': 'Тугмаи «Бақайдгирӣ»-ро пахш кунед, ном, email ва рамзро пур кунед.',
      'faq2q': 'Чӣ тавр профилро навсозӣ кунам?',
      'faq2a': 'Ба саҳифаи Профил равед ва тугмаи таҳрирро пахш кунед.',
      'faq3q': 'Чӣ тавр вакансия нашр кунам?',
      'faq3a': 'Ба ҷадвали «Корҳо» равед ва «Вакансия нашр кунед»-ро пахш кунед.',
      'faq4q': 'Оё ба ҳама паём фиристодан мумкин аст?',
      'faq4a': 'Бале! Ба профили корбар равед ва тугмаи «Паём»-ро пахш кунед.',
      'faq5q': 'Чӣ тавр забони барномаро иваз кунам?',
      'faq5a': 'Менюи паҳлӯро кушоед ва бахши «Забон»-ро ёбед.',
    },
  };
}
