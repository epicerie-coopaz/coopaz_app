//import 'dart:html';

import 'package:coopaz_app/podo/product.dart';
import 'package:coopaz_app/podo/cart_item.dart';
import 'package:coopaz_app/state/app_model.dart';
import 'package:coopaz_app/state/cash_register.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coopaz_app/logger.dart';
import 'package:provider/provider.dart';

class ProductList extends StatefulWidget {
  ProductList({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;
  final NumberFormat numberFormat = NumberFormat('#,##0.00');

  final ScrollController scrollController = ScrollController();

  @override
  State<ProductList> createState() {
    return _ProductList();
  }
}

class _ProductList extends State<ProductList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    log('build productList');

    var styleHeaders = Theme.of(context)
        .primaryTextTheme
        .titleMedium
        ?.apply(color: Theme.of(context).colorScheme.primary);

    AppModel appModel = context.watch<AppModel>();
    CashRegisterModel cashRegisterModel = context.watch<CashRegisterModel>();

    List<Row> productLineWidgets =
        _createProductLineWidgets(appModel, cashRegisterModel);

    return Column(
      children: [
        Row(children: <Widget>[
          Expanded(
              flex: 7,
              child: Text(
                'Produit',
                textScaleFactor: appModel.zoomText,
                style: styleHeaders,
              )),
          Expanded(
              flex: 1,
              child: Text(
                'Qté',
                textScaleFactor: appModel.zoomText,
                style: styleHeaders,
                textAlign: TextAlign.right,
              )),
          Expanded(
              flex: 1,
              child: Text(
                'Prix U.',
                textScaleFactor: appModel.zoomText,
                style: styleHeaders,
                textAlign: TextAlign.right,
              )),
          Expanded(
              flex: 1,
              child: Text(
                'Total',
                textScaleFactor: appModel.zoomText,
                style: styleHeaders,
                textAlign: TextAlign.right,
              )),
          const SizedBox(width: 71),
        ]),
        Expanded(
            child: ListView.builder(
          itemCount: productLineWidgets.length,
          controller: widget.scrollController,
          itemBuilder: (context, index) {
            return productLineWidgets[index];
          },
        )),
        const SizedBox(height: 40),
        Row(children: [
          !cashRegisterModel.isAwaitingSendFormResponse
              ? FloatingActionButton(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    log('+ pressed');
                    _validateAll();
                    cashRegisterModel.addToCart(CartItem());

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.scrollController.hasClients) {
                        widget.scrollController.animateTo(
                            widget.scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut);
                      }
                    });
                  },
                  child: const Icon(Icons.add),
                )
              : Container()
        ]),
      ],
    );
  }

  bool _validateAll() {
    log(widget.formKey.currentState.toString());
    bool valid = false;
    if (widget.formKey.currentState != null) {
      valid = widget.formKey.currentState!.validate();
    }
    return valid;
  }

  List<Row> _createProductLineWidgets(
      AppModel appModel, CashRegisterModel cashRegisterModel) {
    List<Row> products = [];
    for (var entry in cashRegisterModel.cart.asMap().entries) {
      var product = _createProductLineWidget(
          appModel, cashRegisterModel, entry.key, entry.value);
      products.add(product);
    }
    return products;
  }

  Row _createProductLineWidget(AppModel appModel,
      CashRegisterModel cashRegisterModel, int index, CartItem cartItem) {
    var total = '';
    double? unitPrice = cartItem.product?.price;
    double? qty = double.tryParse(cartItem.qty ?? '');
    if (unitPrice != null && qty != null) {
      total = '${widget.numberFormat.format(unitPrice * qty)} €';
    }

    String unitPriceAsString = '';
    if (cartItem.product != null) {
      unitPriceAsString =
          '${cartItem.product?.price}€/${cartItem.product!.unit.unitAsString}';
    }

    var productWidget = Row(children: <Widget>[
      Expanded(
          flex: 7,
          child: !cashRegisterModel.isAwaitingSendFormResponse
              ? FormField<Product>(
                  builder: (formFieldState) {
                    return Autocomplete<Product>(
                      initialValue: TextEditingValue(
                          text: cartItem.product?.designation ?? ''),
                      key: ValueKey(cartItem),
                      displayStringForOption: (Product p) => p.designation,
                      optionsBuilder:
                          (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text == '') {
                          return const Iterable<Product>.empty();
                        }
                        return appModel.products.where((Product p) {
                          return p.stock > 0.0;
                        }).where((Product p) {
                          return p
                              .toString()
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextField(
                          //autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Produit',
                          ),
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          style: TextStyle(fontSize: 14 * appModel.zoomText),
                        );
                      },
                      onSelected: (p) {
                        cashRegisterModel.modifyCartItem(
                            index, CartItem(product: p));
                      },
                    );
                  },
                  validator: (Product? value) {
                    if (value == null) {
                      return 'Produit invalide';
                    }
                    return null;
                  },
                )
              : Text(cashRegisterModel.cart[index].product?.designation ?? '',
                  textScaleFactor: appModel.zoomText)),
      Expanded(
          flex: 1,
          child: !cashRegisterModel.isAwaitingSendFormResponse
              ? TextFormField(
                  controller: TextEditingController(text: cartItem.qty ?? '')
                    ..selection = TextSelection.collapsed(
                        offset: (cartItem.qty ?? '').length),
                  decoration: const InputDecoration(
                    hintText: 'Quantité',
                  ),
                  validator: (String? value) {
                    if (value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null) {
                      return 'Quantité invalide';
                    }
                    return null;
                  },
                  onChanged: (String value) {
                    cartItem.qty = value;
                    cashRegisterModel.modifyCartItem(index, cartItem);
                    _validateAll();
                    _validateAll();
                  },
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14 * appModel.zoomText,
                  ),
                )
              : Text(
                  cashRegisterModel.cart[index].qty ?? '',
                  textAlign: TextAlign.right,
                )),
      Expanded(
          flex: 1,
          child: Text(unitPriceAsString,
              textAlign: TextAlign.right, textScaleFactor: appModel.zoomText)),
      Expanded(
          flex: 1,
          child: Text(
            total,
            textScaleFactor: appModel.zoomText,
            textAlign: TextAlign.right,
          )),
      const SizedBox(width: 15),
      IconButton(
        onPressed: () {
          log('Delete line pressed');
          cashRegisterModel.removeFromCart(index);
        },
        icon: const Icon(Icons.delete),
        tooltip: 'Supprimer ligne',
      )
    ]);

    return productWidget;
  }
}
