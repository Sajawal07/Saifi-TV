import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

// ── Event flavor for cell styling (keyed by month*100 + day) ─────────────────
enum EventFlavor {
  eidFitr,
  eidAdha,
  arafah,
  ashura,
  islamicNewYear,
  milad,
  israMiraj,
  shabBarat,
  laylatulQadr,
  ramadan,
}

class _CalColors {
  static const gold = Color(0xFFD4AF37);
  static const goldBright = Color(0xFFF0C75E);
  static const eidFitrFill = Color(0xFFE8B84B);
  static const eidAdhaFill = Color(0xFFC98A3A);
  static const arafahBorder = Color(0xFFEDE6D6);
  static const ashuraBorder = Color(0xFF5C7A72);
  static const newYearBorder = Color(0xFFC9C2A8);
  static const miladBorder = Color(0xFFD9A688);
  static const israBorder = Color(0xFF5B4B8A);
  static const shabBaratBorder = Color(0xFFB7A6D9);
  static const qadrBorder = Color(0xFFF5EBC8);
  static const ramadanBase = Color(0xFF134A32);
  static const cellBase = Color(0xFF0F3D28);
  static const cellBorder = Color(0xFF1E5C3F);
  static const weekdayBg = Color(0xFF123D2A);
  static const pillBg = Color(0xFF0A2E1F);
  static const gregorian = Color(0xFFF5F5F0);
  static const darkGreenText = Color(0xFF0F3D28);
  static const cream = Color(0xFFF5F3E7);
}

/// Precomputed special-day flavors. Key = hijriMonth * 100 + hijriDay.
const Map<int, EventFlavor> kEventFlavors = {
  // Muharram
  101: EventFlavor.islamicNewYear,
  109: EventFlavor.ashura,
  110: EventFlavor.ashura,
  // Rabi' al-Awwal
  312: EventFlavor.milad,
  // Rajab
  727: EventFlavor.israMiraj,
  // Sha'ban
  815: EventFlavor.shabBarat,
  // Ramadan — Laylatul Qadr nights (override plain Ramadan)
  921: EventFlavor.laylatulQadr,
  923: EventFlavor.laylatulQadr,
  925: EventFlavor.laylatulQadr,
  927: EventFlavor.laylatulQadr,
  929: EventFlavor.laylatulQadr,
  // Shawwal — Eid-ul-Fitr
  1001: EventFlavor.eidFitr,
  1002: EventFlavor.eidFitr,
  1003: EventFlavor.eidFitr,
  // Dhul-Hijjah
  1209: EventFlavor.arafah,
  1210: EventFlavor.eidAdha,
  1211: EventFlavor.eidAdha,
  1212: EventFlavor.eidAdha,
};

const Map<int, List<String>> kNamedEvents = {
  101: ['Islamic New Year'],
  109: ["Tasu'a"],
  110: ['Ashura'],
  312: ['Wiladat-e-Rasool SAW'],
  727: ["Isra wal Mi'raj"],
  815: ["Shab-e-Barat"],
  921: ['Laylatul Qadr'],
  923: ['Laylatul Qadr'],
  925: ['Laylatul Qadr'],
  927: ['Laylatul Qadr'],
  929: ['Laylatul Qadr'],
  1001: ['Eid-ul-Fitr'],
  1002: ['Eid-ul-Fitr'],
  1003: ['Eid-ul-Fitr'],
  1209: ['Yawm-e-Arafah'],
  1210: ['Eid-ul-Adha'],
  1211: ['Eid-ul-Adha'],
  1212: ['Eid-ul-Adha'],
};

EventFlavor? flavorFor(int month, int day) {
  final key = month * 100 + day;
  final specific = kEventFlavors[key];
  if (specific != null) return specific;
  if (month == 9) return EventFlavor.ramadan;
  return null;
}

List<String> eventsFor(int month, int day) {
  final key = month * 100 + day;
  final named = kNamedEvents[key];
  if (named != null) return named;
  if (month == 9) return ['Ramadan Mubarak'];
  return const [];
}

/// Unique named events in a Hijri month (day + label), sorted by day.
List<({int day, String name})> eventsInMonth(int month) {
  final seen = <String>{};
  final list = <({int day, String name})>[];
  for (final entry in kNamedEvents.entries) {
    if (entry.key ~/ 100 != month) continue;
    final day = entry.key % 100;
    for (final name in entry.value) {
      if (seen.add('$day|$name')) {
        list.add((day: day, name: name));
      }
    }
  }
  // Ramadan: show month marker if no other listing needed beyond Qadr nights
  if (month == 9 && list.isEmpty) {
    list.add((day: 1, name: 'Ramadan Mubarak'));
  } else if (month == 9) {
    list.insert(0, (day: 1, name: 'Start of Ramadan'));
  }
  list.sort((a, b) => a.day.compareTo(b.day));
  return list;
}

const List<String> _hijriMonthNames = [
  '',
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhul-Qa'dah",
  'Dhul-Hijjah',
];

const List<String> _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

// ── Islamic Calendar Screen ───────────────────────────────────────────────────
class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  late int _viewYear;
  late int _viewMonth;
  late HijriCalendar _todayHijri;

  @override
  void initState() {
    super.initState();
    _todayHijri = HijriCalendar.now();
    _viewYear = _todayHijri.hYear;
    _viewMonth = _todayHijri.hMonth;
  }

  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  List<_CalDay> _buildDays() {
    final cal = HijriCalendar();
    final daysInMonth = cal.getDaysInMonth(_viewYear, _viewMonth);
    final firstGregorian = cal.hijriToGregorian(_viewYear, _viewMonth, 1);
    // Dart: Mon=1..Sun=7 → Sun-first index 0..6
    final leading = firstGregorian.weekday % 7;

    final cells = <_CalDay>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const _CalDay.empty());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final g = cal.hijriToGregorian(_viewYear, _viewMonth, d);
      final isToday = d == _todayHijri.hDay &&
          _viewMonth == _todayHijri.hMonth &&
          _viewYear == _todayHijri.hYear;
      cells.add(_CalDay(
        hijriDay: d,
        gregorianDay: g.day,
        flavor: flavorFor(_viewMonth, d),
        isToday: isToday,
        isMonthStart: d == 1,
      ));
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    final todayEvents = eventsFor(_todayHijri.hMonth, _todayHijri.hDay);
    final monthEvents = eventsInMonth(_viewMonth);
    // Sun=0 .. Sat=6
    final todayWeekdayIndex = DateTime.now().weekday % 7;

    return Scaffold(
      backgroundColor: _CalColors.cellBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/calender_page_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _CalColors.cellBase),
          ),
          Container(color: Colors.black.withOpacity(0.28)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildMonthPill(),
                const SizedBox(height: 14),
                _buildWeekdayStrip(todayWeekdayIndex),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: days.length,
                          itemBuilder: (_, i) => _DateCell(day: days[i]),
                        ),
                        const SizedBox(height: 14),
                        _MonthEventsSection(
                          monthName: _hijriMonthNames[_viewMonth],
                          year: _viewYear,
                          events: monthEvents,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _TodayEventsCard(events: todayEvents),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'Islamic Calendar',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _CalColors.gold,
                letterSpacing: 0.4,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _CalColors.gold,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPill() {
    final label = '${_hijriMonthNames[_viewMonth]} $_viewYear H';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _CalColors.pillBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _CalColors.gold, width: 1),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left_rounded, color: _CalColors.gold),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _CalColors.gold,
                ),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right_rounded, color: _CalColors.gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayStrip(int todayIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(_weekdays.length, (i) {
          final isToday = i == todayIndex;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? _CalColors.goldBright.withOpacity(0.22)
                    : _CalColors.weekdayBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? _CalColors.goldBright : Colors.transparent,
                  width: isToday ? 1.5 : 0,
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: _CalColors.goldBright.withOpacity(0.35),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _weekdays[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isToday ? _CalColors.goldBright : _CalColors.cream,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CalDay {
  final int? hijriDay;
  final int? gregorianDay;
  final EventFlavor? flavor;
  final bool isToday;
  final bool isMonthStart;

  const _CalDay({
    this.hijriDay,
    this.gregorianDay,
    this.flavor,
    this.isToday = false,
    this.isMonthStart = false,
  });

  const _CalDay.empty()
      : hijriDay = null,
        gregorianDay = null,
        flavor = null,
        isToday = false,
        isMonthStart = false;

  bool get isEmpty => hijriDay == null;
}

// ── Date cell ─────────────────────────────────────────────────────────────────
class _DateCell extends StatelessWidget {
  final _CalDay day;
  const _DateCell({required this.day});

  bool get _hasEidOrAshuraFill =>
      day.flavor == EventFlavor.eidFitr ||
      day.flavor == EventFlavor.eidAdha;

  @override
  Widget build(BuildContext context) {
    if (day.isEmpty) return const SizedBox.shrink();

    final style = _resolveStyle(day.flavor);
    final showCrescent = day.isMonthStart;
    // Slightly smaller only on 1st so crescent fits; others larger & centered
    final gSize = showCrescent ? 11.0 : 13.0;
    final hSize = showCrescent ? 15.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: day.isToday ? _CalColors.goldBright : style.border,
          width: day.isToday ? 2 : style.borderWidth,
        ),
        boxShadow: [
          if (day.isToday)
            BoxShadow(
              color: _CalColors.goldBright.withOpacity(0.55),
              blurRadius: 8,
              spreadRadius: 0.5,
            ),
          ...style.glow,
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (day.flavor == EventFlavor.ramadan)
              Positioned.fill(
                child: CustomPaint(painter: _GoldFleckPainter()),
              ),
            // Numbers always perfectly centered — icons are overlays only
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.gregorianDay}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: gSize,
                    fontWeight: FontWeight.w600,
                    color: style.gregorianColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${day.hijriDay}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: hSize,
                    fontWeight: FontWeight.bold,
                    color: style.hijriColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            if (showCrescent)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.nightlight_round,
                  size: 11,
                  color: _hasEidOrAshuraFill
                      ? _CalColors.darkGreenText.withOpacity(0.85)
                      : _CalColors.goldBright,
                ),
              ),
            if (day.flavor == EventFlavor.eidFitr)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.auto_awesome,
                  size: 9,
                  color: _CalColors.darkGreenText.withOpacity(0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _CellStyle _resolveStyle(EventFlavor? flavor) {
    switch (flavor) {
      case EventFlavor.eidFitr:
        return const _CellStyle(
          fill: _CalColors.eidFitrFill,
          border: _CalColors.eidFitrFill,
          borderWidth: 1,
          gregorianColor: _CalColors.darkGreenText,
          hijriColor: _CalColors.darkGreenText,
        );
      case EventFlavor.eidAdha:
        return const _CellStyle(
          fill: _CalColors.eidAdhaFill,
          border: _CalColors.eidAdhaFill,
          borderWidth: 1,
          gregorianColor: _CalColors.darkGreenText,
          hijriColor: _CalColors.darkGreenText,
        );
      case EventFlavor.arafah:
        return const _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.arafahBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
      case EventFlavor.ashura:
        return const _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.ashuraBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
      case EventFlavor.islamicNewYear:
        return const _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.newYearBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
      case EventFlavor.milad:
        return const _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.miladBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
      case EventFlavor.israMiraj:
        return _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.israBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
          glow: [
            BoxShadow(
              color: _CalColors.israBorder.withOpacity(0.55),
              blurRadius: 6,
            ),
          ],
        );
      case EventFlavor.shabBarat:
        return _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.shabBaratBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
          glow: [
            BoxShadow(
              color: _CalColors.gold.withOpacity(0.35),
              blurRadius: 5,
            ),
          ],
        );
      case EventFlavor.laylatulQadr:
        return _CellStyle(
          fill: _CalColors.ramadanBase,
          border: _CalColors.qadrBorder,
          borderWidth: 2,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
          glow: [
            BoxShadow(
              color: _CalColors.qadrBorder.withOpacity(0.45),
              blurRadius: 7,
            ),
          ],
        );
      case EventFlavor.ramadan:
        return const _CellStyle(
          fill: _CalColors.ramadanBase,
          border: _CalColors.cellBorder,
          borderWidth: 1,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
      case null:
        return const _CellStyle(
          fill: _CalColors.cellBase,
          border: _CalColors.cellBorder,
          borderWidth: 1,
          gregorianColor: _CalColors.gregorian,
          hijriColor: _CalColors.goldBright,
        );
    }
  }
}

class _CellStyle {
  final Color fill;
  final Color border;
  final double borderWidth;
  final Color gregorianColor;
  final Color hijriColor;
  final List<BoxShadow> glow;

  const _CellStyle({
    required this.fill,
    required this.border,
    required this.borderWidth,
    required this.gregorianColor,
    required this.hijriColor,
    this.glow = const [],
  });
}

class _GoldFleckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _CalColors.gold.withOpacity(0.08);
    final rng = math.Random(42);
    for (var i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.8 + rng.nextDouble() * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Month events list (below grid) ────────────────────────────────────────────
class _MonthEventsSection extends StatelessWidget {
  final String monthName;
  final int year;
  final List<({int day, String name})> events;

  const _MonthEventsSection({
    required this.monthName,
    required this.year,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _CalColors.pillBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _CalColors.gold.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events in $monthName $year H',
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _CalColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Text(
              'No major Islamic events this month',
              style: TextStyle(
                fontSize: 13,
                color: _CalColors.cream.withOpacity(0.7),
              ),
            )
          else
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        '${e.day}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _CalColors.goldBright,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: _CalColors.gold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.name,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _CalColors.cream,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Today's Events Card ───────────────────────────────────────────────────────
class _TodayEventsCard extends StatelessWidget {
  final List<String> events;
  const _TodayEventsCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/today_event_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: _CalColors.cellBase),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      const Color(0xFF0A2E1F).withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _CalColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: _CalColors.darkGreenText,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "TODAY'S EVENTS:",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: _CalColors.cream.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (events.isEmpty)
                            Text(
                              'No special events today',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _CalColors.gold.withOpacity(0.85),
                              ),
                            )
                          else
                            ...events.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (events.length > 1)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 7, right: 6),
                                        child: Icon(
                                          Icons.circle,
                                          size: 5,
                                          color: _CalColors.goldBright,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _CalColors.goldBright,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
