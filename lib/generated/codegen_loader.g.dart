// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _en = {
  "app": {
    "name": "Thaheen",
    "tagline": "Learn offline"
  },
  "common": {
    "retry": "Retry",
    "cancel": "Cancel",
    "close": "Close",
    "ok": "OK",
    "back": "Back",
    "minuteShort": "m",
    "secondShort": "s"
  },
  "courses": {
    "title": "My courses",
    "lessonCount": {
      "zero": "No lessons",
      "one": "1 lesson",
      "other": "{} lessons"
    },
    "progressPercent": "{percent}% complete",
    "notStartedYet": "Not started yet",
    "completedCourse": "Course completed",
    "searchHint": "Search a course or instructor",
    "searchNoResults": "No results match your search",
    "searchNoResultsHint": "Try another word or clear the search",
    "empty": "No courses available right now",
    "emptyHint": "Your courses will appear here once added"
  },
  "continueWatching": {
    "title": "Continue watching",
    "subtitle": "Pick up where you left off",
    "resumeAt": "Stopped at {time}",
    "action": "Continue"
  },
  "courseDetails": {
    "instructorLabel": "Instructor",
    "contentTitle": "Course content",
    "sectionCount": {
      "one": "1 section",
      "other": "{} sections"
    },
    "emptySection": "No lessons in this section yet",
    "emptyCourse": "No lessons in this course yet",
    "emptyCourseHint": "Lessons will be added soon",
    "notFound": "We could not find this course",
    "startCourse": "Start course",
    "continueCourse": "Continue course",
    "reviewCourse": "Review course"
  },
  "lesson": {
    "status": {
      "locked": "Locked",
      "notStarted": "Not started",
      "inProgress": "In progress",
      "completed": "Completed"
    },
    "lockedTitle": "This lesson is locked",
    "lockedMessage": "Finish “{title}” first to unlock this lesson",
    "lockedMessageGeneric": "Finish the previous lesson first to unlock this one",
    "next": "Next lesson",
    "nextLocked": "Watch 90% of this lesson to unlock the next one",
    "isLastLesson": "This is the last lesson in the course",
    "courseFinished": "Well done! You finished every lesson",
    "completedToast": "Lesson completed ✅",
    "durationLabel": "Duration"
  },
  "player": {
    "play": "Play",
    "pause": "Pause",
    "replay": "Replay",
    "rewind": "Rewind 10 seconds",
    "forward": "Forward 10 seconds",
    "speed": "Speed",
    "speedLabel": "Playback speed",
    "speedValue": "{value}×",
    "enterFullscreen": "Fullscreen",
    "exitFullscreen": "Exit fullscreen",
    "resumedFrom": "Resumed from {time}",
    "loading": "Preparing the lesson…",
    "seekBarLabel": "Progress bar"
  },
  "settings": {
    "title": "Settings",
    "language": "Language",
    "languageArabic": "العربية",
    "languageEnglish": "English",
    "theme": "Appearance",
    "themeLight": "Light",
    "themeDark": "Dark",
    "themeSystem": "System"
  },
  "errors": {
    "title": "Something went wrong",
    "catalogueMissing": "Course content could not be found",
    "catalogueMissingHint": "The content file seems to be missing from the app",
    "catalogueCorrupt": "Course content is invalid",
    "catalogueCorruptHint": "The content file could not be read correctly",
    "storageUnavailable": "Your progress could not be saved",
    "storageUnavailableHint": "Watch positions may not survive closing the app",
    "videoUnavailable": "This lesson could not be played",
    "videoUnavailableHint": "The video file is missing or corrupt",
    "unexpected": "An unexpected error occurred",
    "unexpectedHint": "Please try again"
  }
};
static const Map<String,dynamic> _ar = {
  "app": {
    "name": "ذاهين",
    "tagline": "تعلّم بلا إنترنت"
  },
  "common": {
    "retry": "إعادة المحاولة",
    "cancel": "إلغاء",
    "close": "إغلاق",
    "ok": "حسناً",
    "back": "رجوع",
    "minuteShort": "د",
    "secondShort": "ث"
  },
  "courses": {
    "title": "دوراتي",
    "lessonCount": {
      "zero": "لا توجد دروس",
      "one": "درس واحد",
      "two": "درسان",
      "few": "{} دروس",
      "many": "{} درساً",
      "other": "{} درس"
    },
    "progressPercent": "{percent}% مكتمل",
    "notStartedYet": "لم تبدأ بعد",
    "completedCourse": "أكملت الدورة",
    "searchHint": "ابحث عن دورة أو مدرّب",
    "searchNoResults": "لا توجد نتائج مطابقة لبحثك",
    "searchNoResultsHint": "جرّب كلمة أخرى أو امسح البحث",
    "empty": "لا توجد دورات متاحة حالياً",
    "emptyHint": "ستظهر دوراتك هنا فور إضافتها"
  },
  "continueWatching": {
    "title": "تابع المشاهدة",
    "subtitle": "أكمل من حيث توقفت",
    "resumeAt": "توقفت عند {time}",
    "action": "متابعة"
  },
  "courseDetails": {
    "instructorLabel": "المدرّب",
    "contentTitle": "محتوى الدورة",
    "sectionCount": {
      "one": "قسم واحد",
      "two": "قسمان",
      "other": "{} أقسام"
    },
    "emptySection": "لا توجد دروس في هذا القسم بعد",
    "emptyCourse": "لا توجد دروس في هذه الدورة بعد",
    "emptyCourseHint": "سيتم إضافة الدروس قريباً",
    "notFound": "لم نعثر على هذه الدورة",
    "startCourse": "ابدأ الدورة",
    "continueCourse": "تابع الدورة",
    "reviewCourse": "مراجعة الدورة"
  },
  "lesson": {
    "status": {
      "locked": "مقفل",
      "notStarted": "لم يبدأ",
      "inProgress": "قيد المشاهدة",
      "completed": "مكتمل"
    },
    "lockedTitle": "هذا الدرس مقفل",
    "lockedMessage": "أكمل درس «{title}» أولاً لفتح هذا الدرس",
    "lockedMessageGeneric": "أكمل الدرس السابق أولاً لفتح هذا الدرس",
    "next": "الدرس التالي",
    "nextLocked": "أكمل ٩٠٪ من هذا الدرس لفتح الدرس التالي",
    "isLastLesson": "هذا آخر درس في الدورة",
    "courseFinished": "أحسنت! أكملت جميع دروس الدورة",
    "completedToast": "تم إكمال الدرس ✅",
    "durationLabel": "المدة"
  },
  "player": {
    "play": "تشغيل",
    "pause": "إيقاف مؤقت",
    "replay": "إعادة التشغيل",
    "rewind": "إرجاع ١٠ ثوانٍ",
    "forward": "تقديم ١٠ ثوانٍ",
    "speed": "السرعة",
    "speedLabel": "سرعة التشغيل",
    "speedValue": "{value}×",
    "enterFullscreen": "ملء الشاشة",
    "exitFullscreen": "إنهاء ملء الشاشة",
    "resumedFrom": "تم الاستئناف من {time}",
    "loading": "جارٍ تحضير الدرس…",
    "seekBarLabel": "شريط التقدم"
  },
  "settings": {
    "title": "الإعدادات",
    "language": "اللغة",
    "languageArabic": "العربية",
    "languageEnglish": "English",
    "theme": "المظهر",
    "themeLight": "فاتح",
    "themeDark": "داكن",
    "themeSystem": "حسب النظام"
  },
  "errors": {
    "title": "حدث خطأ",
    "catalogueMissing": "تعذّر العثور على محتوى الدورات",
    "catalogueMissingHint": "يبدو أن ملف المحتوى غير مرفق مع التطبيق",
    "catalogueCorrupt": "محتوى الدورات غير صالح",
    "catalogueCorruptHint": "تعذّرت قراءة ملف المحتوى بشكل صحيح",
    "storageUnavailable": "تعذّر حفظ تقدّمك",
    "storageUnavailableHint": "قد لا يتم الاحتفاظ بموضع المشاهدة بعد إغلاق التطبيق",
    "videoUnavailable": "تعذّر تشغيل هذا الدرس",
    "videoUnavailableHint": "ملف الفيديو مفقود أو تالف",
    "unexpected": "حدث خطأ غير متوقع",
    "unexpectedHint": "يرجى المحاولة مرة أخرى"
  }
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": _en, "ar": _ar};
}
