import 'dart:convert';
import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:sire_frontend/charts/pie_chart.dart';
import 'package:sire_frontend/charts/vertical_fraction_bar.dart';
import 'package:sire_frontend/colors.dart';
import 'package:sire_frontend/data.dart';
import 'package:sire_frontend/data/options.dart';
import 'package:sire_frontend/formatters.dart';
import 'package:sire_frontend/layout/adaptive.dart';

import 'package:sire_frontend/layout/text_scale.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:sire_frontend/main.dart';
import 'package:sire_frontend/pages/camara.dart';
import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as https;

class CuotasView extends StatelessWidget {

  const CuotasView({
    this.heroLabel,
    this.heroAmount,
    this.wholeAmount,
    this.segments,
    this.financialEntityCards,
    this.totalAbonos,
    this.valorCuota,
  }) : assert(segments.length == financialEntityCards.length);

  /// The amounts to assign each item.
  final List<RallyPieChartSegment> segments;
  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<EntityCuotasView> financialEntityCards;
  final double totalAbonos;
  final double valorCuota;

  @override
  Widget build(BuildContext context) {
    final maxWidth = pieChartMaxSize + (cappedTextScale(context) - 1.0) * 100.0;
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              // We decrease the max height to ensure the [RallyPieChart] does
              // not take up the full height when it is smaller than
              // [kPieChartMaxSize].
              maxHeight: math.min(
                constraints.biggest.shortestSide * 0.9,
                maxWidth,
              ),
            ),
            child: RallyPieChart(
              heroLabel: heroLabel,
              heroAmount: heroAmount,
              wholeAmount: wholeAmount,
              segments: segments,
              totalAbonos: totalAbonos,
              valorCuota: valorCuota,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            constraints: BoxConstraints(maxWidth: maxWidth),
            color: RallyColors.inputBackground,
          ),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            color: RallyColors.cardBackground,
            child: Column(
              children: financialEntityCards,
            ),
          ),
        ],
      );
    });
  }
}

class EntityCuotasView extends StatelessWidget {
  const EntityCuotasView({
    @required this.indicatorColor,
    @required this.indicatorFraction,
    @required this.title,
    @required this.subtitle,
    @required this.semanticsLabel,
    @required this.amount,
    @required this.suffix,
    @required this.cuotas,
  });

  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final String amount;
  final Widget suffix;
  final Future<List<DetailedCuotaData>> cuotas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics.fromProperties(
      properties: SemanticsProperties(
        button: true,
        enabled: true,
        label: semanticsLabel,
      ),
      excludeSemantics: true,
      // TODO(shihaohong): State restoration of
      // FinancialEntityCategoryDetailsPage on mobile is blocked because
      // OpenContainer does not support restorablePush.
      // See https://github.com/flutter/flutter/issues/69924.
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 350),
        transitionType: ContainerTransitionType.fade,
        openBuilder: (context, openContainer) =>
            EntityCuotasDetailsPage(
              numContrato: int.parse(title),
            ),
        openColor: RallyColors.primaryBackground,
        closedColor: RallyColors.primaryBackground,
        closedElevation: 0,
        closedBuilder: (context, openContainer) {
          return TextButton(
            style: TextButton.styleFrom(primary: Colors.black),
            onPressed: openContainer,
            child: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 32 + 60 * (cappedTextScale(context) - 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: VerticalFractionBar(
                          color: indicatorColor,
                          fraction: indicatorFraction,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: textTheme.bodyText2
                                      .copyWith(fontSize: 16),
                                ),
                                Text(
                                  subtitle,
                                  style: textTheme.bodyText2
                                      .copyWith(color: RallyColors.gray60),
                                ),
                              ],
                            ),
                            Text(
                              amount,
                              style: textTheme.bodyText1.copyWith(
                                fontSize: 20,
                                color: RallyColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: suffix,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: RallyColors.dividerColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

EntityCuotasView buildFinancialEntityFromContratoData(
    ContratoData model,
    int accountDataIndex,
    BuildContext context,
    Future<List<DetailedCuotaData>> cuotas,
    ) {
  final amount = usdWithSignFormat(context).format(model.valorContrato);
  final formatter = DateFormat("dd/MM/yyyy");
  final fecha = formatter.format(model.fechaContrato);

  return EntityCuotasView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.numContrato.toString(),
    subtitle: '$fecha',
    semanticsLabel: GalleryLocalizations.of(context).rallyAccountAmount(
      model.numContrato,
      fecha,
      amount,
    ),
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
    amount: "Consultar Cuotas",
    cuotas: cuotas,
  );
}

List<EntityCuotasView> buildContratoDataListViews(
    List<ContratoData> items,
    BuildContext context,
    Future<List<DetailedCuotaData>> cuotas,
    ) {
  return List<EntityCuotasView>.generate(
    items.length,
        (i) => buildFinancialEntityFromContratoData(
        items[i],
        i,
        context,
        cuotas
    ),
  );
}

class EntityCuotasDetailsPage extends StatelessWidget {

  EntityCuotasDetailsPage({this.numContrato,});

  final List<DetailedEventData> items =
  DummyDataService.getDetailedEventItems();
  final int numContrato;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    Future<List<DetailedCuotaData>> _cuotas = getDetailedCuotaItems(numContrato);

    return ApplyTextOptions(
        child: FutureBuilder<List<DetailedCuotaData>>(
            future: _cuotas,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var estado = "RECIBIDO";

              if (snapshot.data.first.estado_cuota == "EN PLANILLA"
                  || snapshot.data.elementAt(1).estado_cuota == "EN PLANILLA") {
                estado = "EN PLANILLA";
              } else if (snapshot.data.first.estado_cuota == "RECHAZADO"
                  || snapshot.data.elementAt(1).estado_cuota == "RECHAZADO") {
                estado = "RECHAZADO";
              } else if (snapshot.data.first.estado_cuota == "CANCELADO"
                  && snapshot.data.elementAt(1).estado_cuota == "CANCELADO") {
                estado = "CANCELADO";
              } else if (snapshot.data.first.estado_cuota == "FACTURADO"
                  && snapshot.data.elementAt(1).estado_cuota == "FACTURADO") {
                estado = "CANCELADO";
              }

              return Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    "Cuotas", //TODO
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        .copyWith(fontSize: 18),
                  ),
                ),
                body: Column(
                  children: [
                    /*SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: RallyLineChart(events: items),
                    ),*/
                    Expanded(
                      child: Padding(
                        padding: isDesktop
                            ? const EdgeInsets.all(40)
                            : EdgeInsets.zero,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _DetailedCuotasCard(
                                    fechaCuota: snapshot.data.first.fechaCuota,
                                    saldoCuota: snapshot.data
                                        .sublist(0, 2).map((detailedEventData) =>
                                    detailedEventData.saldoCuota)
                                        .fold(0, (prev, amount) => prev + amount),
                                    valorAbono: snapshot.data
                                        .sublist(0, 2).map((detailedEventData) =>
                                    detailedEventData.valorAbono)
                                        .fold(0, (prev, amount) => prev + amount),
                                    //valorCuota: detailedEventData.valorCuota,
                                    actualizoPor: snapshot.data.first.actualizoPor,
                                    codCliente: snapshot.data.first.codCliente,
                                    numContrato: numContrato,
                                    nroCuota: snapshot.data.first.nroCuota,
                                    estadoCuota: estado,
                                  ),
                                ),
                                /*TextButton(
                                    onPressed: () => {
                                      if((snapshot.data.first.estado_cuota == "EN PLANILLA" || snapshot.data.elementAt(1).estado_cuota == "EN PLANILLA")
                                          || snapshot.data.first.estado_cuota == "RECHAZADO" || snapshot.data.elementAt(1).estado_cuota == "RECHAZADO")
                                        showDialog(
                                            context: context,
                                            builder: (_) => ImageDialog(
                                              camera: firstCamera,
                                              idCliente: snapshot.data.first.codCliente,
                                              idContrato: numContrato,
                                              idCuota: snapshot.data.first.nroCuota,
                                              estadoCuota: snapshot.data.first.estado_cuota,
                                              saldoCuota: snapshot.data
                                                  .sublist(0, 2).map((detailedEventData) =>
                                              detailedEventData.saldoCuota)
                                                  .fold(0, (prev, amount) => prev + amount),
                                              //valorCuota: valorCuota,
                                            )
                                        )
                                    },
                                    child: Column(
                                      children: [
                                        _EventCuotaTitle(
                                          //title: nroCuota.toString(),
                                          estadoCuota: "TOTAL RESERVA: ",
                                        ),
                                        _EventCuotaAmount(amount: snapshot.data
                                            .sublist(0, 2).map((detailedEventData) =>
                                        detailedEventData.valorAbono)
                                            .fold(0, (prev, amount) => prev + amount)
                                            , estadoCuota: "CANCELADO"
                                        ),
                                      ],
                                    )
                                ),*/
                                IconButton(
                                  onPressed: () => {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        content: Text(
                                          "Valor Facturado.",
                                          style: Theme.of(context)
                                              .textTheme.bodyText1.copyWith(
                                            fontSize: 20,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  },
                                  icon:  Icon(
                                    Icons.warning_amber_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            for (DetailedCuotaData detailedEventData
                            in snapshot.data.sublist(2))
                              Row(
                                children: [
                                  Expanded(
                                    child: _DetailedCuotasCard(
                                      fechaCuota: detailedEventData.fechaCuota,
                                      saldoCuota: detailedEventData.saldoCuota,
                                      valorAbono: detailedEventData.valorAbono,
                                      //valorCuota: detailedEventData.valorCuota,
                                      actualizoPor: detailedEventData.actualizoPor,
                                      codCliente: detailedEventData.codCliente,
                                      numContrato: numContrato,
                                      nroCuota: detailedEventData.nroCuota,
                                      estadoCuota: detailedEventData.estado_cuota,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: hasWarnings(detailedEventData) ? () => {
                                      if (detailedEventData.abonoCapital != 0)
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            content: Text("Abono Capital: " +
                                                usdWithSignFormat(context)
                                                    .format(
                                                    detailedEventData.abonoCapital
                                                ),
                                              style: Theme.of(context)
                                                  .textTheme.bodyText1.copyWith(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      if (isNotBetween(detailedEventData))
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            content: Text("Pago Fuera de Fecha.",
                                              style: Theme.of(context)
                                                  .textTheme.bodyText1.copyWith(
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    }
                                        : null,
                                    icon: Icon(
                                      Icons.warning_amber_outlined,
                                      color: hasWarnings(detailedEventData)
                                          ? RallyColors.accountColors[0]
                                          : Color(0xFF33333D),
                                    ),
                                  ),
                                ],
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _EventCuotaTitle(
                                  //title: nroCuota.toString(),
                                  estadoCuota: "TOTAL: ",
                                ),
                                _EventCuotaAmount(amount: snapshot.data
                                    .sublist(2).map((detailedEventData) =>
                                detailedEventData.valorAbono)
                                    .fold(0, (prev, amount) => prev + amount)
                                    + snapshot.data
                                        .sublist(2).map((detailedEventData) =>
                                    detailedEventData.abonoCapital)
                                        .fold(0, (prev, amount) => prev + amount)
                                    , estadoCuota: "CANCELADO"
                                ),
                                Text(
                                    "    "
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        )
    );
  }

  hasWarnings(DetailedCuotaData detailedEventData) {
    return detailedEventData.abonoCapital != 0
        || isNotBetween(detailedEventData);
  }

  isNotBetween(DetailedCuotaData detailedEventData) {
    DateTime ini = detailedEventData.fechaCuota;
    DateTime fin = detailedEventData.fechaCuota.add(Duration(days: 1));

    return detailedEventData.fechaUltimaAbono
        .isAfter(DateTime.utc(1900))
        && (detailedEventData.fechaUltimaAbono.isBefore(ini)
            || detailedEventData.fechaUltimaAbono.isAfter(fin));
  }

  Future<List<DetailedCuotaData>> getDetailedCuotaItems(int numContrato) async {
    var domain = 'sire.bmcmotors.com.ec';
    var port = '8443';
    var path = '/cuotas/' + numContrato.toString();
    var uri = Uri.https('$domain:$port', path);
    final response = await https.get(uri);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      Iterable l = json.decode(response.body)['items'];
      List<DetailedCuotaData> detailedCuotaDatas = List<DetailedCuotaData>.from(
          l.map((model) => DetailedCuotaData.fromJson(model)));
      return detailedCuotaDatas;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Falla al cargar cuotas');
    }
  }
}

class _DetailedCuotasCard extends StatelessWidget {

  const _DetailedCuotasCard({
    @required this.codCliente,
    @required this.numContrato,
    @required this.nroCuota,
    @required this.fechaCuota,
    @required this.saldoCuota,
    @required this.estadoCuota,
    @required this.actualizoPor,
    @required this.valorAbono,
  });

  final String codCliente;
  final int numContrato;
  final int nroCuota;
  final DateTime fechaCuota;
  final double saldoCuota;
  final double valorAbono;
  final String estadoCuota;
  final String actualizoPor;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    bool isPhoto;
    return TextButton(
      style: TextButton.styleFrom(
        primary: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: (estadoCuota == "EN PLANILLA" || estadoCuota == "RECHAZADO")
          ? () => {
        showDialog(
          context: context,
          builder: (_) => _ImageDialog(),
        ).then((value) => {
          isPhoto = value,
          if (isPhoto == true) {
            if(estadoCuota == "EN PLANILLA"
                || estadoCuota == "RECHAZADO")
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TakePictureScreen(
                          isPhoto: true,
                          camera: firstCamera,
                          idCliente: codCliente,
                          idContrato: numContrato,
                          idCuota: nroCuota,
                          saldoCuota: saldoCuota,
                        )
                ),
              ),
          } else if (isPhoto == false) {
            openGallery(context, codCliente, numContrato, nroCuota, saldoCuota),
          }
        }),
      } : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            child: isDesktop
                ? Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _EventCuotaTitle(
                    //title: nroCuota.toString(),
                    estadoCuota: estadoCuota,
                  ),
                ),
                _EventCuotaDate(
                    date: fechaCuota
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Wrap(
                          spacing: 20,
                          children: [
                            _EventCuotaAmount(
                              amount: valorAbono,
                              estadoCuota: estadoCuota,
                            ),
                            _EventCuotaAmount(
                              amount: saldoCuota,
                              estadoCuota: estadoCuota,
                            ),
                          ]
                      )
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EventCuotaTitle(
                        estadoCuota: estadoCuota,
                      ),
                      _EventCuotaDate(
                          date: fechaCuota
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Abono:"),
                      _EventCuotaAmount(
                        amount: valorAbono,
                        estadoCuota: estadoCuota,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Saldo:"),
                      _EventCuotaAmount(
                        amount: saldoCuota,
                        estadoCuota: estadoCuota,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 1,
            child: Container(
              color: RallyColors.dividerColor,
            ),
          ),
        ],
      ),
    );
  }

  openGallery(BuildContext context, String idCliente, int idContrato
      , int idCuota, double saldoCuota) async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile image = await _picker.pickImage(
        source: ImageSource.gallery
    );
    if (image != null)
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                TakePictureScreen(
                  isPhoto: false,
                  imagePath: image?.path,
                  idCliente: idCliente,
                  idContrato: idContrato,
                  idCuota: idCuota,
                  saldoCuota: saldoCuota,
                )
        ),
      );
  }
}

class _EventCuotaAmount extends StatelessWidget {
  const _EventCuotaAmount({
    Key key,
    @required this.amount,
    @required this.estadoCuota,
  }) : super(key: key);

  final num amount;
  final String estadoCuota;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if(estadoCuota == "RECIBIDO")
      return Text(
        usdWithSignFormat(context).format(amount),
        style: textTheme.bodyText1.copyWith(
          fontSize: 18,
          color: Colors.yellow,
        ),
      );
    else if(estadoCuota == "RECHAZADO")
      return Text(
        usdWithSignFormat(context).format(amount),
        style: textTheme.bodyText1.copyWith(
          fontSize: 18,
          color: Colors.red,
        ),
      );
    else if(estadoCuota == "CANCELADO")
      return Text(
        usdWithSignFormat(context).format(amount),
        style: textTheme.bodyText1.copyWith(
          fontSize: 18,
          color: Colors.green,
        ),
      );
    else
      return Text(
        usdWithSignFormat(context).format(amount),
        style: textTheme.bodyText1.copyWith(
          fontSize: 18,
          color: RallyColors.gray,
        ),
      );
  }
}

class _EventCuotaDate extends StatelessWidget {
  const _EventCuotaDate({Key key, @required this.date}) : super(key: key);

  final DateTime date; //TODO

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      shortDateFormat(context).format(date), //TODO
      semanticsLabel: longDateFormat(context).format(date), //TODO
      style: textTheme.bodyText2.copyWith(
        color: RallyColors.gray60,
        fontSize: 8,
      ),
    );
  }
}

class _EventCuotaTitle extends StatelessWidget {
  const _EventCuotaTitle({
    Key key,
    //@required this.title,
    @required this.estadoCuota,
  }) : super(key: key);

  //final String title;
  final String estadoCuota;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      //title + " " + estadoCuota,
      estadoCuota,
      style: textTheme.bodyText2.copyWith(fontSize: 9),
    );
  }
}

class _ImageDialog extends StatelessWidget {
  const _ImageDialog({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text("Cámara: "),
              IconButton(
                icon: Icon(
                  Icons.add_a_photo_outlined,
                  color: RallyColors.accountColors[0],
                ),
                iconSize: 45,
                alignment: Alignment.topRight,
                padding: EdgeInsets.zero,
                onPressed: () => {
                  Navigator.pop(context, true),
                },
              ),
            ],
          ),
          Column(
            children: [
              Text("Galería: "),
              IconButton(
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: RallyColors.accountColors[0],
                ),
                iconSize: 45,
                alignment: Alignment.topRight,
                padding: EdgeInsets.zero,
                onPressed: () => {
                  Navigator.pop(context, false),
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}