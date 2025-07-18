import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/widgets/app_exit_card_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/sign_in_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/sign_up_widget.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    Provider.of<AuthController>(context, listen: false).updateSelectedIndex(0, notify: false);
    super.initState();
  }

  bool scrolled = false;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable default back behavior
      onPopInvoked: (didPop) async {
        if (didPop) return; // If already popped, do nothing

        final authController = Provider.of<AuthController>(context, listen: false);

        if (authController.selectedIndex != 0) {
          // If not on the first tab, switch to it instead of popping
          authController.updateSelectedIndex(0);
        } else {
          // If on first tab, handle back press
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Show exit confirmation
            final shouldExit = await showModalBottomSheet<bool>(backgroundColor: Colors.transparent, context: context, builder: (_) => const AppExitCard()) ?? false;

            if (shouldExit && mounted) {
              Navigator.pop(context);
            }
          }
        }
      },
      child: Scaffold(
        body: Consumer<AuthController>(
          builder: (context, authProvider, _) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(height: 200, decoration: BoxDecoration(color: Theme.of(context).primaryColor)),
                      Image.asset(Images.loginBg, fit: BoxFit.cover, height: 200, opacity: const AlwaysStoppedAnimation(.15)),
                      Padding(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * .05),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset(Images.splashLogo, width: 130, height: 100)]),
                      ),
                    ],
                  ),

                  AnimatedContainer(
                    transform: Matrix4.translationValues(0, -20, 0),
                    curve: Curves.fastOutSlowIn,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
                    ),
                    duration: const Duration(seconds: 2),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(Dimensions.marginSizeLarge),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => authProvider.updateSelectedIndex(0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated('login', context)!,
                                          style: authProvider.selectedIndex == 0 ? textRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge) : textRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                                        ),
                                        Container(
                                          height: 3,
                                          width: 25,
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall), color: authProvider.selectedIndex == 0 ? Theme.of(context).primaryColor : Colors.transparent),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                                  InkWell(
                                    onTap: () => authProvider.updateSelectedIndex(1),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated('sign_up', context)!,
                                          style: authProvider.selectedIndex == 1 ? titleRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge) : titleRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                                        ),
                                        Container(
                                          height: 3,
                                          width: 25,
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall), color: authProvider.selectedIndex == 1 ? Theme.of(context).primaryColor : Colors.transparent),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            authProvider.selectedIndex == 0 ? const SignInWidget() : const SignUpWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
