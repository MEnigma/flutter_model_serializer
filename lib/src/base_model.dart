/*
* Copyright © 2019 mark , All rights reserved
* author : mark
* date : 2019-08-12
* ide : VSCode
*/

import 'dart:core';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'base_field.dart';
export 'base_field.dart';

class BaseModel with ModelCacheManager{

  /// 元数据
  Map _oriData;

  /// 主键
  AnyValueField _primaryField;


  BaseModel(){
    createDataTable(createTableSql());
  }
  BaseModel.fromJson(Map<String, dynamic> data) {
    createDataTable(createTableSql());
    if (data != null) {
      _oriData = data;
      formatData(_oriData);
    } else {
      print("< MODEL($runtimeType) > 格式化数据产生空值 ");
    }
  }

  /// 从本地数据初始化
  Future initFromLocal(String where, List whereArgs) async {
    Map data = await fetchPieceOfData(where, whereArgs);
    if(data != null){
      formatData(data);
    }
  }

  /// 创建表命令
  String createTableSql(){
    String command = "CREATE TABLE IF NOT EXISTS ${tableName()}";
    String values = "";

    List comParts = [];
    for (AnyValueField item in propertyList()) {
      String com = (" ${item.mkey} ${item.dataType()} ");
      if (item.isPrimaryKey){
        com += "PRIMARY KEY ";
      }
      comParts.add(com);
    }

    command += ("(${comParts.join(",")})");
    return command;
  }

  /// 表名称
  String tablename;

  Map<String, dynamic> toDict() {
    Map<String, dynamic> val = {};
    for (AnyValueField field in propertyList()) {
      try {
        val[field.mkey.toString()] = field.anyValue();
      } catch (e) {
        print("< MODEL($runtimeType) $e>");
      }
    }
    return val;
  }

  void formatData(Map data) {
    if (data == null) return;
    for (AnyValueField field in propertyList()) {
      field.setDynamicValue(data[field.mkey]);
    }
  }

  /// 属性列表
  List<AnyValueField> propertyList() {
    return [];
  }

  /// 主键
  AnyValueField get primaryField {
    if (_primaryField == null) {
      for (AnyValueField field in propertyList()) {
        if (field.isPrimaryKey == true) {
          _primaryField = field;
          break;
        }
      }
    }
    return _primaryField;
  }

  @override
  String primaryKey() {
    // TODO: implement primaryKey
    return primaryField.mkey;
  }
  @override
  String primaryValue() {
    // TODO: implement primaryValue
    return primaryField.anyValue();
  }

  @override
  String tableName() {
    // TODO: implement tableName
    return tablename ??= runtimeType.toString();
  }

  @override
  Future updateRaw({String priValue, Map<String, dynamic> vals, String where, List whereArgs}) {
    // TODO: implement updateRaw
    return super.updateRaw(priValue: primaryValue(),vals: toDict());
  }
  @override
  Future insertRaw({Map<String, dynamic> rawData}) {
    // TODO: implement insertRaw
    return super.insertRaw(rawData: rawData??toDict());
  }
}

const String DBNAME = "MAIN_DB.db";

/// model缓存处理
class ModelCacheManager {
  /// 数据库
  Database _dataBase;

  /// 类方法,
  static Future<List<Map>> _fetchAllFromLocal() async {
    return await ModelCacheManager().fetchData();
  }

  /// 表名
  String tableName() {
    return runtimeType.toString();
  }

  /// 主键名称
  String primaryKey() {
    return "";
  }
  String primaryValue(){
    return "";
  }

  Future connectToDatabase() async {
    Directory cache_dir = await getApplicationDocumentsDirectory();
    String dbPath = cache_dir.path.toString() + "/" + "db";
    Directory dbDir = Directory(dbPath);
    if (await dbDir.exists() == false) {
      dbDir.create(recursive: false);
    }
    print("dbpath : $dbPath");
    _dataBase = await openDatabase(dbPath+'/$DBNAME');
    return _dataBase;
  }

  /// 创建数据表
  Future createDataTable(String createSqlCom) async {
    _dataBase ??= await connectToDatabase();
    await _dataBase.execute(createSqlCom);
  }

  /// 获取所有数据
  Future<List<Map>> fetchData() async {
    _dataBase ??= await connectToDatabase();
    return await _dataBase.query(tableName());
  }

  /// 获取某条数据
  Future<Map> fetchPieceOfData(String where, List args) async {
    _dataBase ??= await connectToDatabase();
    List<Map> resList =
        await _dataBase.query(tableName(), where: where, whereArgs: args);
    if (resList != null && resList.length > 0) {
      return resList[0];
    }
    return null;
  }

  /// 更新某条数据
  Future updateRaw({String priValue ,Map<String, dynamic> vals,String where ,List whereArgs}) async {
    _dataBase ??= await connectToDatabase();
    priValue ??= primaryValue();
    if(await fetchPieceOfData(primaryKey(), [priValue]) != null){
      //有值更新
      return await _dataBase.update(tableName(), vals, where: where, whereArgs: whereArgs);
    }else{
      // 无值插入
      return await insertRaw(rawData:vals);
    }
  }

  /// 插入数据
  Future insertRaw({Map<String,dynamic> rawData}) async {
    _dataBase ??= await connectToDatabase();
    return await _dataBase.insert(tableName(), rawData);
  }

  /// 删除数据
  Future deleteRawData({String where,List whereArgs}) async {
    _dataBase ??= await connectToDatabase();

    where ??= primaryKey();
    whereArgs ??= [primaryValue()];

    return await _dataBase.delete(tableName(),where: where,whereArgs: whereArgs);
  }
}
