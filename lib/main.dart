import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './ui/screen.dart';
import './models/auth_token.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async {
  // (1) Load the .env file
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          // (2) Create and provide AuthManager
          ChangeNotifierProvider(
            create: (context) => AuthManager(),
          ),
          ChangeNotifierProxyProvider<AuthManager, ProductManger>(
            // create: (ctx) => ProductManger(),
            create: (ctx) => ProductManger(),
            update: (ctx, authManager, productsManager) {
              // Khi authManager có báo hiệu thay đổi thì đọc lại authToken
              // cho productManager
              productsManager!.authToken = authManager.authToken;
              return productsManager;
            },
          ),
          ChangeNotifierProvider(
            create: (ctx) => CartManager(),
          ),
          ChangeNotifierProvider(
            create: (ctx) => OrdersManager(),
          )
        ],
        child: Consumer<AuthManager>(builder: (ctx, authManager, child) {
          return MaterialApp(
            title: 'My Shop',
            // tắt chế độ gỡ lỗi
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                fontFamily: 'Lato',
                colorScheme: ColorScheme.fromSwatch(
                  primarySwatch: Colors.purple,
                ).copyWith(
                  secondary: Colors.deepOrange,
                )),
            home: authManager.isAuth
                ? const ProductsOverviewScreen()
                : FutureBuilder(
                    future: authManager.tryAutoLogin(),
                    builder: (ctx, snapshot) {
                      return snapshot.connectionState == ConnectionState.waiting
                          ? const SplashScreen()
                          : const AuthScreen();
                    },
                  ),
            routes: {
              CartScreen.routeName: (context) => const CartScreen(),
              OrdersScreen.routeName: (context) => const OrdersScreen(),
              UserProductsScreen.routeName: (context) =>
                  const UserProductsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == EditProductScreen.routeName) {
                final productId = settings.arguments as String?;
                return MaterialPageRoute(builder: (ctx) {
                  return EditProductScreen(productId != null
                      ? ctx.read<ProductManger>().findById(productId)
                      : null);
                });
              }
              return null;
            },
          );
        }));
  }
}
