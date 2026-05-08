import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

void main(List<String> arguments) async {
  late final sqlite3.Database database;

  debugPrint(
    join((await getApplicationDocumentsDirectory()).path, 'habit_tracker.db'),
  );

  try {
    database = sqlite3.sqlite3.open(
      join((await getApplicationDocumentsDirectory()).path, 'habit_tracker.db'),
      mutex: true,
    );
  } catch (e) {
    debugPrint(e.toString());
    return;
  }
  try {
    database.execute(
      'CREATE TABLE IF NOT EXISTS v1 (title TEXT PRIMARY KEY, type INTEGER, metadata TEXT, "1" BOOLEAN, "2" BOOLEAN, "3" BOOLEAN, "4" BOOLEAN, "5" BOOLEAN, "6" BOOLEAN, "7" BOOLEAN, "8" BOOLEAN, "9" BOOLEAN, "10" BOOLEAN, "11" BOOLEAN, "12" BOOLEAN, "13" BOOLEAN, "14" BOOLEAN, "15" BOOLEAN, "16" BOOLEAN, "17" BOOLEAN, "18" BOOLEAN, "19" BOOLEAN, "20" BOOLEAN, "21" BOOLEAN, "22" BOOLEAN, "23" BOOLEAN, "24" BOOLEAN, "25" BOOLEAN, "26" BOOLEAN, "27" BOOLEAN, "28" BOOLEAN, "29" BOOLEAN, "30" BOOLEAN, "31" BOOLEAN);',
    );
  } catch (e) {
    debugPrint(e.toString());
    return;
  }
  if (arguments.isNotEmpty) {
    final title = arguments[0].toUpperCase();
    try {
      final recordExists = database.select(
        'SELECT EXISTS(SELECT 1 FROM v1 WHERE title = ?);',
        [title],
      );
      if (recordExists.first.values.first == 0) {
        database.execute(
          'INSERT INTO v1 (title, type, metadata) VALUES (?, ?, ?);',
          [title, 0, ''],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
    debugPrint(arguments.toString());
    runApp(MyApp(database: database, habitTitle: title));
  }
}

class MyApp extends StatelessWidget {
  final sqlite3.Database database;
  final String habitTitle;
  const MyApp({super.key, required this.database, required this.habitTitle});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      darkTheme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.lightGreen, brightness: .dark),
      ),
      home: MyHomePage(title: habitTitle, database: database),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.database});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final sqlite3.Database database;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum TrackerType {
  week(0),
  month(1),
  year(2);

  final int value;

  const TrackerType(this.value);

  static TrackerType fromInt(int value) {
    switch (value) {
      case 0:
        return TrackerType.week;
      case 1:
        return TrackerType.month;
      case 2:
        return TrackerType.year;
      default:
        return TrackerType.month;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late String _title;
  late List<bool> _daysCompleted;
  late TrackerType _trackerType;
  late final TextEditingController _titleEditingController;

  @override
  void initState() {
    super.initState();

    _title = widget.title;
    _titleEditingController = TextEditingController(text: _title);

    _titleEditingController.addListener(() {
      widget.database.execute('UPDATE v1 SET title = ? WHERE title = ?;', [
        _titleEditingController.text,
        _title,
      ]);
      _title = _titleEditingController.text;
    });

    final habit = widget.database.select('SELECT * FROM v1 WHERE title = ?;', [
      widget.title,
    ]);

    _trackerType = TrackerType.fromInt(
      habit.first['type'] ?? TrackerType.month.value,
    );

    _daysCompleted = [];
    for (var i = 1; i <= 31; i++) {
      debugPrint(habit.first['$i'].toString());
      _daysCompleted.add(habit.first['$i'] == 1);
    }
  }

  void _updateDayCompletion(int day, bool isCompleted) {
    try {
      widget.database.execute(
        'UPDATE v1 SET "${day + 1}" = ? WHERE title = ?;',
        [isCompleted ? 1 : 0, _title],
      );
      setState(() {
        _daysCompleted[day] = isCompleted;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: TextField(
          controller: _titleEditingController,
          inputFormatters: [UpperCaseTextFormatter()],
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: .center,
          children: [
            Expanded(
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.
                mainAxisAlignment: .center,
                crossAxisAlignment: .center,
                children: [
                  Expanded(
                    child: switch (_trackerType) {
                      TrackerType.week => WeekTracker(
                        daysCompleted: _daysCompleted,
                        onDayChangeCallback: _updateDayCompletion,
                      ),
                      TrackerType.month => MonthTracker(
                        daysCompleted: _daysCompleted,
                        onDayChangeCallback: _updateDayCompletion,
                      ),
                      TrackerType.year => YearTracker(
                        daysCompleted: _daysCompleted,
                        onDayChangeCallback: _updateDayCompletion,
                      ),
                    },
                  ),
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      DropdownButton<TrackerType>(
                        // isDense: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 27,
                        ),
                        iconSize: 27,
                        value: _trackerType,
                        items: [
                          DropdownMenuItem<TrackerType>(
                            value: TrackerType.week,
                            child: Text('7📆'),
                          ),
                          DropdownMenuItem<TrackerType>(
                            value: TrackerType.month,
                            child: Text('31📆'),
                          ),
                          DropdownMenuItem<TrackerType>(
                            value: TrackerType.year,
                            child: Text('12📆'),
                          ),
                        ],
                        onChanged: (TrackerType? newValue) => setState(() {
                          _trackerType = newValue ?? TrackerType.month;
                          widget.database.execute(
                            'UPDATE v1 SET type = ? WHERE title = ?;',
                            [_trackerType.value, _title],
                          );
                        }),
                        underline: SizedBox(),
                        iconEnabledColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                      MaterialButton(
                        onPressed: () {
                          setState(() {
                            for (
                              var day = 0;
                              day < _daysCompleted.length;
                              day++
                            ) {
                              try {
                                widget.database.execute(
                                  'UPDATE v1 SET "${day + 1}" = ? WHERE title = ?;',
                                  [0, _title],
                                );
                              } catch (e) {
                                debugPrint(e.toString());
                              }
                              _daysCompleted[day] = false;
                            }
                          });
                        },
                        child: Text('🧼', style: TextStyle(fontSize: 27)),
                      ),
                    ],
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

class WeekTracker extends StatelessWidget {
  final List<bool> daysCompleted;
  final void Function(int, bool) onDayChangeCallback;
  const WeekTracker({
    super.key,
    required this.daysCompleted,
    required this.onDayChangeCallback,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: .contain,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: .center,
        spacing: 4,
        children: List.generate(7, (index) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primaryContainer,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: daysCompleted[index]
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
            ),
            margin: EdgeInsets.zero,
            width: 50,
            height: 60,
            child: MaterialButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                onDayChangeCallback(index, !daysCompleted[index]);
              },
            ),
          );
        }),
      ),
    ),
  );
}

class MonthTracker extends StatelessWidget {
  final List<bool> daysCompleted;
  final void Function(int, bool) onDayChangeCallback;
  const MonthTracker({
    super.key,
    required this.daysCompleted,
    required this.onDayChangeCallback,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: .contain,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(
        spacing: 4,
        crossAxisAlignment: .center,
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(7, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index, !daysCompleted[index]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(7, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 7]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 7, !daysCompleted[index + 7]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(7, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 14]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 14, !daysCompleted[index + 14]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(7, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 21]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 21, !daysCompleted[index + 21]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}

class YearTracker extends StatelessWidget {
  final List<bool> daysCompleted;
  final void Function(int, bool) onDayChangeCallback;
  const YearTracker({
    super.key,
    required this.daysCompleted,
    required this.onDayChangeCallback,
  });

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: .contain,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(
        spacing: 4,
        crossAxisAlignment: .center,
        children: [
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(3, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index, !daysCompleted[index]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(3, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 3]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 3, !daysCompleted[index + 3]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(3, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 6]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 6, !daysCompleted[index + 6]);
                  },
                ),
              );
            }),
          ),
          Row(
            mainAxisAlignment: .center,
            spacing: 4,
            children: List.generate(3, (index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: daysCompleted[index + 9]
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                ),
                margin: EdgeInsets.zero,
                width: 50,
                height: 50,
                child: MaterialButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    onDayChangeCallback(index + 9, !daysCompleted[index + 9]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    ),
  );
}
