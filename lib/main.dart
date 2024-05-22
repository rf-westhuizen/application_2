import 'dart:ui';

import 'package:audit_db_package/audit_db_package.dart';
import 'package:device_info_fetcher/device_info_fetcher.dart';
import 'package:flutter/material.dart';
import 'package:scotch_dev_error/logging/logging.dart';
import 'package:sqlite_postgresql_connector/sqlite_postgresql_connector.dart';
import 'package:yaml_parser_fetcher/yaml_parser_fetcher.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/isolate.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:shared_database/shared_database.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Ensure that we wait a bit to give time for Application 1 to register the isolate
  await Future.delayed(const Duration(seconds: 2));

  // Look up the registered isolate's send port
  final sendPort = IsolateNameServer.lookupPortByName('drift_isolate');
  if (sendPort == null) {
    throw Exception('Failed to find the Drift isolate. Ensure Application 1 is running.');
  }

  final driftIsolate = DriftIsolate.fromConnectPort(sendPort);

  runApp(MyApp(driftIsolate: driftIsolate));


}

class MyApp extends StatelessWidget {
  final DriftIsolate driftIsolate;

  const MyApp({super.key, required this.driftIsolate});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(driftIsolate: driftIsolate,),
    );
  }
}
class HomeScreen extends StatelessWidget {
  final DriftIsolate driftIsolate;

  HomeScreen({required this.driftIsolate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Application 2')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final connection = await driftIsolate.connect();
                final db = SharedDatabase(connection);
                for (var i = 0; i < 100; i++) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  final userId = await db.into(db.userTable).insert(UserTableCompanion.insert(name: 'User from App 2'));
                  print('Inserted user with id: $userId');
                }
              },
              child: Text('Insert Users from App 2'),
            ),
            ElevatedButton(
              onPressed: () async {
                final connection = await driftIsolate.connect();
                final db = SharedDatabase(connection);
                final users = await db.select(db.userTable).get();
                for (var user in users) {
                  print('User: ${user.id}, ${user.name}');
                }
              },
              child: Text('Fetch Users from App 2'),
            ),
          ],
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    kDebugPrint('inside application 2:');
    final localDb = AuditDb.local();
    final remoteDb = AuditDb.postgres();
  }


  void _incrementCounter() {
    setState(() {
      runInsert();
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
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
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void runInsert() async {

    // Getting the required information.
    final deviceSerial = await getDeviceInfo().aSyncSerial;
    final deviceSoftware = await getYamlData().aSyncSoftware;
    final deviceVersion = await getYamlData().aSyncVersion;

    for (var i = 0; i < 10; i++) {
      final record = ScotchPaymentRequest(
        id: UuidValue.fromString(Uuid().v4()).toString(),
        serial: deviceSerial,
        origin: 'Pepkor DateTime test',
        software: deviceSoftware,
        version: deviceVersion,
        refId: 'Pepkor - E65',
        refType: RefType.none,
        tenderType: TenderType.unknown,
        synced: false,
        //date: PgDateTime(resultDate),
        //date: PgDateTime(DateTime.now()),
        date: PgDateTimeExt.now(),
        transactionId: null,
        amount: 7850,
        cashBack: null,
        tip: null,
        callbackUrl: null,
        ts: 1661930423,
      );

      // insert into the local sqlite
      final localDb = await AuditDb.local();
      await localDb.auditDao.createRequest(record);

      kDebugPrint('Record inserted: $record');

    }

  }


}
