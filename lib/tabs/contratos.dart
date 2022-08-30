// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:sire_frontend/charts/pie_chart.dart';
import 'package:sire_frontend/data.dart';
import 'package:sire_frontend/pages/cuotas.dart';
import 'package:sire_frontend/tabs/sidebar.dart';

/// A page that shows a summary of accounts.
class ContratosView extends StatelessWidget {
  var contratoDatas;
  var cuotas;

  ContratosView({this.contratoDatas, this.cuotas});

  @override
  Widget build(BuildContext context) {
    final items = contratoDatas;
    final detailItems = DummyDataService.getAccountDetailList(context);
    final balanceTotal = sumContratoDataPrimaryAmount(items);

    return TabWithSidebar(
      restorationId: 'accounts_view',
      mainView: CuotasView(
        heroLabel: "Certificado de Compra", //GalleryLocalizations.of(context).rallyAccountTotal,
        heroAmount: balanceTotal,
        segments: buildSegmentsFromContratoItems(items),
        wholeAmount: balanceTotal,
        financialEntityCards: buildContratoDataListViews(
          items,
          context,
          cuotas,
        ),
        totalAbonos: items[0].totalAbonos,
        valorCuota: items[0].valorCuota,
      ),
      sidebarItems: [
        for (UserDetailData item in detailItems)
          SidebarItem(title: item.title, value: item.value)
      ],
    );
  }
}
