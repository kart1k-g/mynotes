import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_events.dart';
import 'package:mynotes/services/auth/bloc/auth_states.dart';
import 'package:bloc/bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState>{
  AuthBloc(AuthProvider provider): super(const AuthStateLoading()){
    on<AuthEventInitalize>((event, emit)async {
        await provider.initalize();
        final user=provider.currentUser;
        if(user==null){
            emit(AuthStateLoggedOut());
        }else if(!user.isEmailVerified){
            emit(AuthStateNeedsVerificaton());
        }else{
            emit(AuthStateLoggedIn(user));
        }
    });   

    on<AuthEventLogIn>((event, emit)async {
        emit(AuthStateLoading());
        final email=event.email;
        final password=event.password;
        try{
            final user=await provider.logInUser(email: email, password: password);
            emit(AuthStateLoggedIn(user));
        }on Exception catch (e){
            emit(AuthStateLogInFailure(exception: e));
        }
    });

    on<AuthEventLogOut>((event, emit)async {
      emit(AuthStateLoading());
      try{
        await provider.logOutUser();
        emit(AuthStateLoggedOut());
      }on Exception catch(e){
        emit(AuthStateLogOutFailure(exception: e));
      }
    },);
  }
  
}