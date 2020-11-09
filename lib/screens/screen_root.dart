import 'package:flutter/material.dart';
import 'package:mahlmann_app/blocs/bloc_root.dart';
import 'package:provider/provider.dart';

class ScreenRoot extends StatelessWidget {
	
  @override
  Widget build(BuildContext context) {
    return Provider<BlocRoot>(
	    create: (context) => BlocRoot(),
	    dispose: (context, value) => value.dispose(),
	    child: ViewRoot(),
	    lazy: false,
    );
  }
}

class ViewRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object>(
      stream: null,
      builder: (context, snapshot) {
        return Container();
      }
    );
  }
}

