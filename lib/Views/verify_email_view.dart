import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        late final email;
        if(state is AuthLoggedOut){
          email=state.user?.email;
        }else{
          email=null;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Email Verification"),
            backgroundColor: Colors.deepPurple,
          ),
          body: Padding(
            padding: const EdgeInsetsGeometry.all(16.0),
            child: Column(
              children: [
                Text(
                  "Email verifiaction sent on $email",
                ),
                
                const SizedBox(height: 10,),
                
                TextButton(
                  onPressed: (){
                    context.read<AuthBloc>().add(AuthEmailVerificationRequested());
                  },
                  child: const Text("Resend email verification"),
                ),
                
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      AuthConfirmEmailVerificationRequested(),
                    );
                  },
                  child: const Text("Email verified"),
                ),
                
                TextButton(
                  onPressed: () {
                    //until user is verified we don't want it in the db
                    context.read<AuthBloc>().add(
                      AuthDeleteUserRequested(displayRegisterView: false),
                    );
                    context.read<AuthBloc>().add(
                      AuthLogOutRequested(displayRegisterView: true),
                    );
                  },
                  child: const Text("Use another account"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
