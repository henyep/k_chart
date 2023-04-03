import 'package:k_chart/entity/cci_entity.dart';
import 'package:k_chart/entity/kdj_entity.dart';
import 'package:k_chart/entity/rsi_entity.dart';
import 'package:k_chart/entity/rw_entity.dart';

mixin MACDEntity on KDJEntity, RSIEntity, WREntity, CCIEntity {
  double? dea;
  double? dif;
  double? macd;
}
