import 'package:flutter/material.dart';
import 'package:mahlmann_app/blocs/bloc_preloader.dart';
import 'package:mahlmann_app/widgets/dialogs/one_action_dialog.dart';
import 'package:mahlmann_app/widgets/exception_handler.dart';
import 'package:mahlmann_app/widgets/m_progress_indicator.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';


class ScreenPreloader extends StatelessWidget {
	final Function onFetched;

	 ScreenPreloader(this.onFetched);

	@override
	Widget build(BuildContext context) {
		return Provider<BlocPreloader>(
			create: (context) => BlocPreloader(this.onFetched),
			dispose: (context, value) => value.dispose(),
			child: ViewPreloader(),
			lazy: false,
		);
	}
}

class ViewPreloader extends StatefulWidget {

  @override
  _ViewPreloaderState createState() => _ViewPreloaderState();
}

class _ViewPreloaderState extends State<ViewPreloader> {
  @override
  Widget build(BuildContext context) {
    return ExceptionHandler<BlocPreloader>(
	    onException: (e) {
		    showDialog(
				    context: context,
				    barrierDismissible: false,
				    builder: (BuildContext context) => OneActionDialog(
				    title: context.loc.errorTitle ?? "",
				    message: e.toString(),
				    btnTitle: context.loc.btnOk,
		    ));
	    },
      child: Container(
	    color: Colors.white,
	    child: Stack(
		    children: <Widget>[
			    Positioned.fill(
				    child: Center(
					    child: SizedBox(
						    width: 150,
						    height: 200,
						    child: Image.asset(
							    'assets/images/app_logo.png',
							    fit: BoxFit.contain,
						    ),
					    ),
				    ),
			    ),
			    Positioned(
				    child: MProgressIndicator(),
				    left: 0,
				    right: 0,
				    bottom: 0,
			    ),
		    ],
	    ),
      ),
    );
  }
}
