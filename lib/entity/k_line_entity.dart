import 'package:k_chart/entity/k_entity.dart';

class KLineEntity extends KEntity {
  late double? amount;
  double? change;
  double? ratio;
  int? time;

  KLineEntity.fromCustom({
    required double open,
    required double high,
    required double low,
    required double close,
    required double vol,
    this.amount,
    this.change,
    this.ratio,
  }) {
    this.open = open;
    this.high = high;
    this.low = low;
    this.close = close;
    this.vol = vol;
  }

  KLineEntity.fromJson(Map<String, dynamic> json) {
    open = json['open'] != null ? json['open'] as double : 0;
    high = json['high'] != null ? json['high'] as double : 0;
    low = json['low'] != null ? json['low'] as double : 0;
    close = json['close'] != null ? json['close'] as double : 0;
    vol = json['vol'] != null ? json['vol'] as double : 0;
    amount = json['amount'] != null ? json['amount'] as double : 0;
    var tempTime = json['time'] != null ? json['time'] as int : null;
    // TODO: REMOVE FOLLOWING STATEMENT
    // Compatible with Huobi(https://www.huobi.com/en-us/) data
    if (tempTime == null) {
      tempTime = json['id'] != null ? json['id'] as int : 0;
      tempTime = tempTime * 1000;
    }
    time = tempTime;
    ratio = json['ratio'] != null ? json['ratio'] as double : null;
    change = json['change'] != null ? json['change'] as double : null;
  }

  @override
  String toString() {
    return 'MarketModel{open: $open, high: $high, low: $low, close: $close, vol: $vol, time: $time, amount: $amount, ratio: $ratio, change: $change}';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    data['time'] = time;
    data['open'] = open;
    data['close'] = close;
    data['high'] = high;
    data['low'] = low;
    data['vol'] = vol;
    data['amount'] = amount;
    data['ratio'] = ratio;
    data['change'] = change;

    return data;
  }
}
