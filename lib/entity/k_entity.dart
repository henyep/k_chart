import 'package:k_chart/entity/candle_entity.dart';
import 'package:k_chart/entity/cci_entity.dart';
import 'package:k_chart/entity/kdj_entity.dart';
import 'package:k_chart/entity/macd_entity.dart';
import 'package:k_chart/entity/rsi_entity.dart';
import 'package:k_chart/entity/rw_entity.dart';
import 'package:k_chart/entity/volume_entity.dart';

class KEntity
    with
        CandleEntity,
        VolumeEntity,
        KDJEntity,
        RSIEntity,
        WREntity,
        CCIEntity,
        MACDEntity {}
