import 'package:flutter/material.dart';
import 'package:mahlmann_app/widgets/mahlmann_progress_indicator.dart';

class ScreenPreloader extends StatelessWidget {
	final Function onFetched;

  const ScreenPreloader({Key key, this.onFetched}) : super(key: key);
	
  @override
  Widget build(BuildContext context) {
    return Container(
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
				    child: MahlmannProgressIndicator(),
				    left: 0,
				    right: 0,
				    bottom: 0,
			    ),
		    ],
	    ),
    );
  }
}
