import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/map_opener.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/widgets/m_text_field.dart';
import 'package:mahlmann_app/widgets/m_dialog.dart';
import 'package:mahlmann_app/common/extensions.dart';

class FieldInfoDialog extends StatefulWidget {
  final Field field;

  const FieldInfoDialog(
    this.field, {
    Key key,
  }) : super(key: key);

  @override
  _FieldInfoDialogState createState() => _FieldInfoDialogState();
}

class _FieldInfoDialogState extends State<FieldInfoDialog> {

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final bloc = context.provide<BlocMap>();
    return MDialog(
      child: StreamBuilder<List<Comment>>(
          stream: bloc.fieldComments,
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: DialogButton(
                    title: loc.route,
                    action: () {
                      final c = widget.field.coordinates.firstOrNull;
                      if (c.latitude != null && c.longitude != null) {
                        final urls = MapOpener.buildMapUrls(
                            location: LatLng(c.latitude, c.longitude));
                        MapOpener.openMap(urls);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                InfoRow(loc.name, widget.field.name),
                InfoRow(loc.status, widget.field.status),
                InfoRow(loc.cabbage, widget.field.isCabbage),
                InfoRow(
                    loc.titleArea,
                    widget.field.areaSize != null
                        ? "${widget.field.areaSize.toStringAsFixed(2)} ha"
                        : null),
                Text(loc.comments),
                for (Comment c in comments) InfoRow(c.user, c.text),
                const SizedBox(height: 8),
                MTextField(
                  hint: loc.comment,
                  onSubmitted: (comment) {
                    // clear text field ???
                    bloc.onSubmitComment(widget.field.id, comment);
                  },
                ),
              ],
            );
          }),
      btnTitle: loc.close,
    );
  }
}

class InfoRow extends StatelessWidget {
  final String name;
  final String value;

  const InfoRow(
    this.name,
    this.value, {
    Key key,
  })  : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("${name ?? ""}: ",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
            )),
        Text(value ?? "n/a", style: TextStyle(fontSize: 15)),
      ],
    );
  }
}
