/*
* Copyright © 2019 mark , All rights reserved
* author : mark
* date : 2019-08-12
* ide : VSCode
*/

import 'dart:convert';

import "package:flutter/material.dart";

abstract class BaseField extends Object {
  BaseField(this.mkey, {this.isPrimaryKey = false});

  BaseField.withPrimary(
    this.mkey,
  ) {
    isPrimaryKey = true;
  }

  /// 数据,由子类空值赋值
  var _value;

  /// 字段名称,用于同步本地
  String mkey = "";

  /// 是否为主键(sql)
  bool isPrimaryKey = false;

  /// 数据类型,由子类实现
  String dataType() {
    return "";
  }
}

class AnyValueField extends BaseField {
  AnyValueField(String keyname, {bool isPrimaryKey = false})
      : super(keyname, isPrimaryKey: isPrimaryKey);
  AnyValueField.withPrimary(String keyname)
      : super(keyname, isPrimaryKey: true);

  ///fixme 需要在子类中重写用于规定类型
  void setDynamicValue(var value) {
    if (value == null) return;
    _value = value;
  }

  ///fixme 可由子类重写规定数据类型
  dynamic anyValue() {
    return _value;
  }
}

/// 字符串形
class CharField extends AnyValueField {
  CharField(String keyname) : super(keyname);
  CharField.primary(String keyname) : super(keyname, isPrimaryKey: true);

  /// 内容
  String get text => (_value ??= "").toString();

  @override
  String dataType() => "TEXT";

  set text(String value) {
    _value = value.toString();
  }
}

abstract class NumberField extends AnyValueField {
  NumberField(String keyname) : super(keyname);
  num get number => _value ??= 0;
  set number(num value) {
    if (value == null) return;
    _value = value;
  }
}

class DoubleField extends NumberField {
  DoubleField(String keyname) : super(keyname);
  double get float => super.number.toDouble();
  set float(double value) {
    number = value;
  }

  @override
  String dataType() => "REAL";
}

class IntegerField extends NumberField {
  IntegerField(String keyname) : super(keyname);
  int get integer => super.number.toInt();
  set integer(int value) {
    number = value;
  }

  @override
  String dataType() => "INTEGER";
}

/// 容器类型
class ArrayField extends AnyValueField {
  ArrayField(String keyname) : super(keyname);
  List get array => _value ??= [];

  operator +(List other) {
    array.addAll(other);
  }

  dynamic operator [](int location) {
    return array[location];
  }

  void add(var object) {
    if (object != null) array.add(object);
  }

  int get length {
    return array.length;
  }

  bool setValueFromJsonString(String jsonStr) {
    List decode_val = [];
    try {
      decode_val = jsonDecode(jsonStr);
      _value = decode_val;
      return true;
    } catch (e) {
      print("< MODEL($runtimeType) > 数据数据json反序列化错误:$e ");
      return false;
    }
  }

  @override
  String dataType() => "TEXT";

  @override
  void setDynamicValue(value) {
    // TODO: implement setDynamicValue
    if (value.runtimeType.toString() == "String") {
      //json解析
      setValueFromJsonString(value);
    } else if (value.runtimeType.toString() == "List") {
      //字典
      _value = value;
    } else {
      print("< MODEL($runtimeType) > 解析类型错误 : ${value.runtimeType} ");
      super.setDynamicValue(value);
    }
  }

  @override
  anyValue() {
    // TODO: implement anyValue
    try {
      return jsonEncode(array);
    } catch (e) {
      return super.anyValue();
    }
  }
}

class DictField extends AnyValueField {
  DictField(String keyname) : super(keyname);
  DictField.fromJsonString(String keyname, String jsonStr) : super(keyname) {
    setValueFromJsonString(jsonStr);
  }
  Map<String, dynamic> get dict => _value ??= {};

  List<String> get keys {
    return dict.keys.toList();
  }

  @override
  String dataType() {
    // TODO: implement dataType
    return "TEXT";
  }

  bool setValueFromJsonString(String jsonStr) {
    Map decode_val = {};
    try {
      decode_val = jsonDecode(jsonStr);
      _value = decode_val;
      return true;
    } catch (e) {
      print("< MODEL($runtimeType) > 字典数据json反序列化错误:$e ");
      return false;
    }
  }

  @override
  void setDynamicValue(value) {
    // TODO: implement setDynamicValue
    if (value.runtimeType.toString() == "String") {
      //json解析
      setValueFromJsonString(value);
    } else if (value.runtimeType.toString() == "Map") {
      //字典
      _value = value;
    } else {
      super.setDynamicValue(value);
      print("< MODEL($runtimeType) > 解析类型错误 : ${value.runtimeType} ");
    }
  }

  @override
  anyValue() {
    // TODO: implement anyValue
    try {
      return jsonEncode(dict);
    } catch (e) {
      return super.anyValue();
    }
  }
}
