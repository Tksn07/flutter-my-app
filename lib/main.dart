/// Flutter関係のインポート
import 'package:my_app/firestore_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Firebase関係のインポート
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 他ページのインポート
import 'package:my_app/normal_counter_page.dart';
import 'package:my_app/crash_page.dart';
import 'package:my_app/auth_page.dart';
import 'package:my_app/remote_config_page.dart';

/// メイン
void main() async {
  /// クラッシュハンドラ
  runZonedGuarded<Future<void>>(() async {
    /// Firebaseの初期化
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    /// クラッシュハンドラ(Flutterフレームワーク内でスローされたすべてのエラー)
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    /// runApp w/ Riverpod
    runApp(const ProviderScope(child: MyApp()));
  },

      /// クラッシュハンドラ(Flutterフレームワーク内でキャッチされないエラー)
      (error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

/// Providerの初期化
/// カウンター用のプロバイダー
final counterProvider = StateNotifierProvider.autoDispose<Counter, int>((ref) {
  return Counter();
});

class Counter extends StateNotifier<int> {
  Counter() : super(0);

  /// カウントアップ
  void increment() {
    print("testtesttest");
    state++;
  }
}

/// MaterialAppの設定
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter Firebase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// ホーム画面
class MyHomePage extends ConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ログイン状態の確認
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (user == null) {
          ref.watch(userEmailProvider.state).state = 'ログインしていません';
        } else {
          ref.watch(userEmailProvider.state).state = user.email!;
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Homepage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: <Widget>[
          /// ユーザ情報の表示
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person),
              Text(ref.watch(userEmailProvider)),
            ],
          ),

          /// 各ページへの遷移
          const _PagePushButton(
            buttonTitle: 'ノーマルカウンター',
            pagename: NormalCounterPage(),
          ),
          const _PagePushButton(
            buttonTitle: 'クラッシュページ',
            pagename: CrashPage(),
          ),
          const _PagePushButton(
            buttonTitle: 'Remote Configカウンター',
            pagename: RemoteConfigPage(),
          ),
          const _PagePushButton(
            buttonTitle: '認証ページ',
            pagename: AuthPage(),
            bgColor: Colors.red,
          ),

          /// 各ページへの遷移(認証後利用可能)
          /// 認証されていなかったらボタンを押せない状態にする
          const _PagePushButton(
                  buttonTitle: 'Firestoreカウンター',
                  pagename: FirestorePage(),
                  bgColor: Colors.green,
                )
        ],
      ),
    );
  }
}

/// ページ遷移のボタン
class _PagePushButton extends StatelessWidget {
  const _PagePushButton({
    Key? key,
    required this.buttonTitle,
    required this.pagename,
    this.bgColor = Colors.blue,
  }) : super(key: key);

  final String buttonTitle;
  final dynamic pagename;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(bgColor),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Text(buttonTitle),
      ),
      onPressed: () {
        AnalyticsService().logPage(buttonTitle);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pagename),
        );
      },
    );
  }
}

/// Analyticsの実装
class AnalyticsService {
  /// ページ遷移のログ
  Future<void> logPage(String screenName) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'screen_view',
      parameters: {
        'firebase_screen': screenName,
      },
    );
  }
}