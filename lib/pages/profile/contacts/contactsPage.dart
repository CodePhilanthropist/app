import 'package:app/pages/profile/contacts/contactPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';
import 'package:polkawallet_ui/components/v3/iconButton.dart' as v3;
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class ContactsPage extends StatefulWidget {
  ContactsPage(this.service);

  final AppService service;

  static final String route = '/profile/contacts';

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<KeyPairData> _list = [];

  void _refreshData() {
    setState(() {
      _list = widget.service.keyring.contacts;
    });
  }

  Future<void> _showActions(BuildContext pageContext, KeyPairData i) async {
    final dic = I18n.of(pageContext).getDic(i18n_full_dic_ui, 'common');
    final res = await showCupertinoModalPopup(
      context: pageContext,
      builder: (BuildContext context) => PolkawalletActionSheet(
        actions: <Widget>[
          PolkawalletActionSheetAction(
            child: Text(
              dic['edit'],
            ),
            onPressed: () async {
              Navigator.of(context).pop(0);
              await Navigator.of(context)
                  .pushNamed(ContactPage.route, arguments: i);
              _refreshData();
            },
          ),
          PolkawalletActionSheetAction(
            child: Text(
              dic['copy'],
            ),
            onPressed: () async {
              Navigator.of(context).pop(1);
            },
          ),
          PolkawalletActionSheetAction(
            child: Text(
              dic['delete'],
            ),
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop(2);
              _removeItem(pageContext, i);
            },
          )
        ],
        cancelButton: PolkawalletActionSheetAction(
          child: Text(
            dic['cancel'],
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
    if (res == 1) {
      UI.copyAndNotify(context, i.address);
    }
  }

  void _removeItem(BuildContext context, KeyPairData i) {
    var dic = I18n.of(context).getDic(i18n_full_dic_ui, 'common');
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PolkawalletAlertDialog(
          title: Text(I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['contact.delete.warn']),
          content: Text(UI.accountName(context, i)),
          actions: <Widget>[
            PolkawalletActionSheetAction(
              child: Text(dic['cancel']),
              onPressed: () => Navigator.of(context).pop(),
            ),
            PolkawalletActionSheetAction(
              isDefaultAction: true,
              child: Text(dic['ok']),
              onPressed: () async {
                Navigator.of(context).pop();
                await widget.service.keyring.store.deleteContact(i.pubKey);
                if (i.observation &&
                    widget.service.keyring.store.currentPubKey == i.pubKey) {
                  if (widget.service.keyring.allAccounts.length > 0) {
                    widget.service.keyring
                        .setCurrent(widget.service.keyring.allAccounts[0]);

                    widget.service.account.handleAccountChanged(
                        widget.service.keyring.allAccounts[0]);
                  } else {
                    widget.service.keyring.setCurrent(KeyPairData());
                  }
                }
                _refreshData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _list = widget.service.keyring.contacts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_app, 'profile')['contact']),
          centerTitle: true,
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: v3.IconButton(
                icon: Icon(Icons.add,
                    color:
                        UI.isDarkTheme(context) ? Colors.black : Colors.white),
                isBlueBg: true,
                onPressed: () async {
                  await Navigator.of(context).pushNamed(ContactPage.route);
                  _refreshData();
                },
              ),
            )
          ],
          leading: BackBtn()),
      body: SafeArea(
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: _list.map((i) {
            return RoundedCard(
              margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
              child: ListTile(
                dense: true,
                leading: AddressIcon(i.address, svg: i.icon, size: 36.w),
                title: Text(
                  UI.accountName(context, i),
                  style: Theme.of(context).textTheme.headline4,
                ),
                subtitle: Text(Fmt.address(i.address),
                    style: Theme.of(context).textTheme.headline6),
                onTap: () => _showActions(context, i),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
