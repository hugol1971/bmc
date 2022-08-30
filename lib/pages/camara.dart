import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sire_frontend/data/options.dart';
import 'package:sire_frontend/layout/adaptive.dart';
import 'package:sire_frontend/layout/text_scale.dart';

import 'package:http/http.dart' as https;

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:async_button_builder/async_button_builder.dart';

import 'home.dart';

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String idCliente;
  final int idContrato;
  final int idCuota;
  final double saldoCuota;
  final bool isPhoto;
  final String imagePath;

  const TakePictureScreen({
    Key key,
    this.camera,
    @required this.idCliente,
    @required this.idContrato,
    @required this.idCuota,
    @required this.saldoCuota,
    @required this.isPhoto,
    this.imagePath,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> with RestorationMixin {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  final RestorableTextEditingController _fechaReciboController =
  RestorableTextEditingController();
  final RestorableTextEditingController _valorReciboController =
  RestorableTextEditingController();
  final RestorableTextEditingController _nroDocumentController =
  RestorableTextEditingController();

  @override
  String get restorationId => 'camara_page';

  @override
  void restoreState(RestorationBucket oldBucket, bool initialRestore) {
    registerForRestoration(_fechaReciboController, restorationId);
    registerForRestoration(_valorReciboController, restorationId);
    registerForRestoration(_nroDocumentController, restorationId);
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    if (widget.isPhoto == true)
      _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPhoto == false)
      return DisplayPictureScreen(
        imagePath: widget.imagePath,
        fechaReciboController: _fechaReciboController.value,
        valorReciboController: _valorReciboController.value,
        nroDocumentController: _nroDocumentController.value,
        idCliente: widget.idCliente,
        idContrato: widget.idContrato,
        idCuota: widget.idCuota,
        saldoCuota: widget.saldoCuota,
      );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Foto Recibo", //TODO
          style: Theme.of(context)
              .textTheme
              .bodyText2
              .copyWith(fontSize: 18),
        ),
      ),
      body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(
                _controller,
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(
                    imagePath: image?.path,
                    fechaReciboController: _fechaReciboController.value,
                    valorReciboController: _valorReciboController.value,
                    nroDocumentController: _nroDocumentController.value,
                    idCliente: widget.idCliente,
                    idContrato: widget.idContrato,
                    idCuota: widget.idCuota,
                    saldoCuota: widget.saldoCuota,
                  )
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {

  const DisplayPictureScreen({
    Key key,
    @required this.imagePath,
    @required this.fechaReciboController,
    @required this.valorReciboController,
    @required this.nroDocumentController,
    @required this.idCliente,
    @required this.idContrato,
    @required this.idCuota,
    @required this.saldoCuota,
  }) : super(key: key);

  final String imagePath;
  final TextEditingController fechaReciboController;
  final TextEditingController valorReciboController;
  final TextEditingController nroDocumentController;
  final String idCliente;
  final int idContrato;
  final int idCuota;
  final double saldoCuota;

  Future<void> _showMyDialog(BuildContext context, String titulo, String mensaje) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(mensaje),
              ],
            ),
          ),
          backgroundColor: Colors.black,
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _send(BuildContext context) async {
    if(valorReciboController.value.text.isEmpty ||
        fechaReciboController.value.text.isEmpty ||
        nroDocumentController.value.text.isEmpty) {
      _showMyDialog(context, 'Advertencia', 'Deber llenar todos los campos.');
      return;
    }

    double valorReciboFinal = double.parse(valorReciboController.value.text
        .replaceAll(",", ""));

    /*if(saldoCuota < valorReciboFinal) {
      _showMyDialog(context, 'Advertencia', 'Valor del Recibo incorrecto.');
      return;
    }*/

    var domain = 'sire.bmcmotors.com.ec';
    var port = '8443';
    var path = '/medias/';
    var uri = Uri.https('$domain:$port', path);

    var headers = <String,String>{
      'Content-type' : 'application/json',
      'Accept': 'application/json',
      'file_name': idCliente + '-' + idContrato.toString() + '-'
          + idCuota.toString() + '.jpg',
      'file_type': 'image/jpeg'
    };

    var response = await https.post(
        uri,
        body: File(this.imagePath).readAsBytesSync(),
        headers: headers
    );

    print('response.statusCode -> ' + response.statusCode.toString());
    print('response.statusCode -> ' + response.body);

    if(response.statusCode == 201) {
      int id = json.decode(response.body)['id'];
      print('id -> ' + id.toString());

      path = '/recibos/';
      uri = Uri.https('$domain:$port', path);

      var body = json.encode(
          {
            'id': id,
            'fecha_recibo': fechaReciboController.text,
            'cod_cliente': idCliente,
            'num_contrato': idContrato,
            'nro_cuota': idCuota,
            'cod_forma_pago': "EFECTIVO",
            'nro_recibo_documento': nroDocumentController.text,
            "valor_recibo": valorReciboFinal,
            "valor_cuota": saldoCuota
          }
      );

      var headers = <String,String>{
        'Content-type' : 'application/json',
        'Accept': 'application/json',
      };

      print('fecha_recibo -> ' + fechaReciboController.text);
      print('valor_recibo -> ' + valorReciboController.value.text);
      print('cod_cliente -> ' + idCliente);
      print('num_contrato -> ' + idContrato.toString());
      print('nro_cuota -> ' + idCuota.toString());
      print('cod_forma_pago -> ' + "EFECTIVO");
      print('nro_recibo_documento -> ' + nroDocumentController.text);
      print('valor_recibo -> ' + valorReciboController.value.text);
      print('valor_cuota -> ' + saldoCuota.toString());

      var response2 = await https.post(uri, body: body, headers: headers);

      print('response2.statusCode -> ' + response2.statusCode.toString());
      print('response2.body -> ' + response2.body);

      if(response2.statusCode == 201) {
        _showMyDialog(context, 'Envío Exitoso', 'Recibo Enviado Exitosamente.');
      } else {
        _showMyDialog(context, 'Envío Fallido', 'Contáctese con BMC.');
      }

      Navigator.push(
          context,
          new MaterialPageRoute(
            builder: (BuildContext context) => new HomePage(
              numContrato: idContrato,
            ),
          )
      );
    } else {
      _showMyDialog(context, 'Envío Fallido', 'Contáctese con BMC.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApplyTextOptions(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Info Recibo", //TODO
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: 18),
          ),
        ),
        body: _MainView(
          imageController: Image.file(
            File(imagePath),
            height: 450,
          ),
          imagePath: imagePath,
          fechaReciboController: fechaReciboController,
          valorReciboController: valorReciboController,
          nroDocumentController: nroDocumentController,
          idCliente: idCliente,
          idContrato: idContrato,
          idCuota: idCuota,
          valorCuota: saldoCuota,
        ),
        floatingActionButton: AsyncButtonBuilder(
          child: Icon(Icons.send),
          onPressed: () async {
            await _send(context);
          },
          builder: (context, child, callback, _) {
            return FloatingActionButton(
              child: child,
              onPressed: callback,
            );
          },
        ),
      ),
    );
  }
}

class _MainView extends StatelessWidget {

  const _MainView({
    Key key,
    this.imageController,
    this.imagePath,
    this.fechaReciboController,
    this.valorReciboController,
    this.nroDocumentController,
    this.idCliente,
    this.idContrato,
    this.idCuota,
    this.valorCuota
  }) : super(key: key);

  final Image imageController;
  final String imagePath;
  final TextEditingController fechaReciboController;
  final TextEditingController valorReciboController;
  final TextEditingController nroDocumentController;
  final String idCliente;
  final int idContrato;
  final int idCuota;
  final double valorCuota;

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    List<Widget> listViewChildren;

    if (isDesktop) {
      final desktopMaxWidth = 400.0 + 100.0 * (cappedTextScale(context) - 1);
      listViewChildren = [
        imageController,
        const SizedBox(height: 12),
        _FechaCuotaInput(
          maxWidth: desktopMaxWidth,
          fechaCuotaController: fechaReciboController,
        ),
        const SizedBox(height: 12),
        _ValorCuotaInput(
          maxWidth: desktopMaxWidth,
          valorCuotaController: valorReciboController,
        ),
        const SizedBox(height: 12),
        _NroDocumentCuotaInput(
          nroDocumentController: nroDocumentController,
        ),
      ];
    } else {
      listViewChildren = [
        //const SizedBox(height: 5),
        imageController,
        const SizedBox(height: 10),
        _FechaCuotaInput(
          fechaCuotaController: fechaReciboController,
        ),
        const SizedBox(height: 10),
        _ValorCuotaInput(
          valorCuotaController: valorReciboController,
        ),
        const SizedBox(height: 10),
        _NroDocumentCuotaInput(
          nroDocumentController: nroDocumentController,
        ),
      ];
    }

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: isDesktop ? Alignment.center : Alignment.topCenter,
            child: ListView(
              restorationId: 'login_list_view',
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: listViewChildren,
            ),
          ),
        ),
      ],
    );
  }
}

class _FechaCuotaInput extends StatelessWidget {

  _FechaCuotaInput({
    Key key,
    this.maxWidth,
    this.fechaCuotaController,
  }) : super(key: key);

  final double maxWidth;
  final TextEditingController fechaCuotaController;
  final format = DateFormat("dd/MM/yyyy");

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Column(children: <Widget>[
          DateTimeField(
              textInputAction: TextInputAction.next,
              controller: fechaCuotaController,
              decoration: InputDecoration(
                labelText: 'Fecha Recibo',//GalleryLocalizations.of(context).rallyLoginUsername,
              ),
              format: format,
              onShowPicker: (context, currentValue) {
                return showDatePicker(context: context, initialDate: currentValue ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2100));
              }
          ),
        ],
        ),
      ),
    );
  }
}

class _ValorCuotaInput extends StatelessWidget {

  const _ValorCuotaInput({
    Key key,
    this.maxWidth,
    this.valorCuotaController,
  }) : super(key: key);

  final double maxWidth;
  final TextEditingController valorCuotaController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: TextField(
          inputFormatters: [CurrencyTextInputFormatter(symbol: '')],
          keyboardType: TextInputType.number,
          controller: valorCuotaController,
          decoration: InputDecoration(
            labelText: 'Valor Recibo',//GalleryLocalizations.of(context).rallyLoginPassword,
          ),
          obscureText: false,
        ),
      ),
    );
  }
}

class _NroDocumentCuotaInput extends StatelessWidget {

  const _NroDocumentCuotaInput({
    Key key,
    this.maxWidth,
    this.nroDocumentController,
  }) : super(key: key);

  final double maxWidth;
  final TextEditingController nroDocumentController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: TextField(
          textInputAction: TextInputAction.next,
          controller: nroDocumentController,
          decoration: InputDecoration(
            labelText: 'Nro. Documento',//GalleryLocalizations.of(context).rallyLoginPassword,
          ),
        ),
      ),
    );
  }
}