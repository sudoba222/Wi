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
    },
  };
}
