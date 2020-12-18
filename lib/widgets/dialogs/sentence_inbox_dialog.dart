import 'package:flutter/material.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';
import 'package:mahlmann_app/common/extensions.dart';

class SentenceInboxDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.provide<BlocMap>();
    final loc = context.loc;
    return MDialog(
      child: StreamBuilder<List<Group>>(
          stream: bloc.inboxGroups,
          builder: (context, snapshot) {
            final groups = snapshot.data;
            return Align(
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groups == null || groups.isEmpty)
                    Text(loc.noSets)
                  else
                    for (Group g in groups)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(g.name ?? ""),
                          ),
                          onTap: () async {
                            bloc.handleSentence(g.fieldIds.toList());
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                  DialogButton(
                    title: loc.deselect,
                    action: () {
                      bloc.clearInboxFields();
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
            );
          }),
      btnTitle: loc.close,
    );
  }
}
