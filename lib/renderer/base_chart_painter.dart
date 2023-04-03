import 'dart:math';

import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:k_chart/chart_style.dart' show ChartStyle;
import 'package:k_chart/entity/k_line_entity.dart';
import 'package:k_chart/k_chart_widget.dart';
import 'package:k_chart/utils/date_format_util.dart';

export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity>? entityList;
  MainState mainState;

  SecondaryState secondaryState;

  bool volHidden;
  bool isTapShowInfoDialog;
  double scaleX = 1.0;
  double scrollX = 0.0;
  double selectX;
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;

  //3块区域大小与位置
  late Rect mMainRect;
  Rect? mVolRect;
  Rect? mSecondaryRect;
  late double mDisplayHeight;
  late double mWidth;
  double mTopPadding = 30.0;
  double mBottomPadding = 20.0;
  double mChildPadding = 12.0;
  int mGridRows = 4;
  int mGridColumns = 4;
  int mStartIndex = 0;
  int mStopIndex = 0;
  double mMainMaxValue = double.minPositive;
  double mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive;
  double mVolMinValue = double.maxFinite;
  double mSecondaryMaxValue = double.minPositive;
  double mSecondaryMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0;
  double mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive;
  double mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; //数据占屏幕总长度
  final ChartStyle chartStyle;
  late double mPointWidth;
  List<String> mFormats = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn,
  ]; //格式化时间
  double xFrontPadding;

  BaseChartPainter(
    this.chartStyle, {
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.xFrontPadding,
    this.entityList,
    this.isOnTap = false,
    this.mainState = MainState.MA,
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryState = SecondaryState.MACD,
    this.isLine = false,
  }) {
    mItemCount = entityList?.length ?? 0;
    mPointWidth = chartStyle.pointWidth;
    mTopPadding = chartStyle.topPadding;
    mBottomPadding = chartStyle.bottomPadding;
    mChildPadding = chartStyle.childPadding;
    mGridRows = chartStyle.gridRows;
    mGridColumns = chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
//    return oldDelegate.datas != datas ||
//        oldDelegate.datas?.length != datas?.length ||
//        oldDelegate.scaleX != scaleX ||
//        oldDelegate.scrollX != scrollX ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.selectX != selectX ||
//        oldDelegate.isLine != isLine ||
//        oldDelegate.mainState != mainState ||
//        oldDelegate.secondaryState != secondaryState;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(
      Rect.fromLTRB(
        0,
        0,
        size.width,
        size.height,
      ),
    );
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (entityList != null && entityList!.isNotEmpty) {
      drawChart(canvas, size);
      drawVerticalText(canvas);
      drawDate(canvas, size);

      drawText(canvas, entityList!.last, 5);
      drawMaxAndMin(canvas);
      drawNowPrice(canvas);

      if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
        drawCrossLineText(canvas, size);
      }
    }
    canvas.restore();
  }

  void initFormats() {
    final dateTimeFormat = chartStyle.dateTimeFormat;

    if (dateTimeFormat != null) {
      mFormats = dateTimeFormat;

      return;
    }

    if (mItemCount < 2) {
      mFormats = [
        yyyy,
        '-',
        mm,
        '-',
        dd,
        ' ',
        HH,
        ':',
        nn,
      ];

      return;
    }

    final firstTime = entityList?.first.time ?? 0;
    final secondTime = entityList?[1].time ?? 0;
    final time = (secondTime - firstTime) ~/ 1000;
    // Monthly line
    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '-', mm];
    } else if (time >= 24 * 60 * 60) {
      mFormats = [
        yy,
        '-',
        mm,
        '-',
        dd,
      ];
    } else {
      mFormats = [
        mm,
        '-',
        dd,
        ' ',
        HH,
        ':',
        nn,
      ];
    }
  }

  void initChartRenderer();

  //画背景
  void drawBg(Canvas canvas, Size size);

  //画网格
  void drawGrid(Canvas canvas);

  //画图表
  void drawChart(Canvas canvas, Size size);

  //画右边值
  void drawVerticalText(Canvas canvas);

  //画时间
  void drawDate(Canvas canvas, Size size);

  //画值
  void drawText(Canvas canvas, KLineEntity data, double x);

  //画最大最小值
  void drawMaxAndMin(Canvas canvas);

  //画当前价格
  void drawNowPrice(Canvas canvas);

  //画交叉线
  void drawCrossLine(Canvas canvas, Size size);

  //交叉线值
  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    final volHeight = !volHidden ? mDisplayHeight * 0.2 : 0;
    final secondaryHeight =
        secondaryState != SecondaryState.NONE ? mDisplayHeight * 0.2 : 0;

    final mainHeight = mDisplayHeight - volHeight - secondaryHeight;

    mMainRect = Rect.fromLTRB(
      0,
      mTopPadding,
      mWidth,
      mTopPadding + mainHeight,
    );

    if (!volHidden) {
      mVolRect = Rect.fromLTRB(
        0,
        mMainRect.bottom + mChildPadding,
        mWidth,
        mMainRect.bottom + volHeight,
      );
    }

    //secondaryState == SecondaryState.NONE隐藏副视图
    if (secondaryState != SecondaryState.NONE) {
      mSecondaryRect = Rect.fromLTRB(
        0,
        mMainRect.bottom + volHeight + mChildPadding,
        mWidth,
        mMainRect.bottom + volHeight + secondaryHeight,
      );
    }
  }

  void calculateValue() {
    final entities = entityList;
    if (entities == null) {
      return;
    }
    if (entities.isEmpty) {
      return;
    }

    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));

    for (var i = mStartIndex; i <= mStopIndex; i++) {
      final item = entities[i];
      getMainMaxMinValue(item, i);
      getVolMaxMinValue(item);
      getSecondaryMaxMinValue(item);
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    double maxPrice;
    double minPrice;
    if (mainState == MainState.MA) {
      maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.BOLL) {
      maxPrice = max(item.up ?? 0, item.high);
      minPrice = min(item.dn ?? 0, item.low);
    } else {
      maxPrice = item.high;
      minPrice = item.low;
    }
    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i.toDouble();
    }

    if (isLine) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  void getVolMaxMinValue(KLineEntity item) {
    mVolMaxValue = max(
      mVolMaxValue,
      max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)),
    );
    mVolMinValue = min(
      mVolMinValue,
      min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)),
    );
  }

  void getSecondaryMaxMinValue(KLineEntity item) {
    if (secondaryState == SecondaryState.MACD) {
      if (item.macd != null) {
        mSecondaryMaxValue =
            max(mSecondaryMaxValue, max(item.macd!, max(item.dif!, item.dea!)));
        mSecondaryMinValue =
            min(mSecondaryMinValue, min(item.macd!, min(item.dif!, item.dea!)));
      }
    } else if (secondaryState == SecondaryState.KDJ) {
      if (item.d != null) {
        mSecondaryMaxValue =
            max(mSecondaryMaxValue, max(item.k!, max(item.d!, item.j!)));
        mSecondaryMinValue =
            min(mSecondaryMinValue, min(item.k!, min(item.d!, item.j!)));
      }
    } else if (secondaryState == SecondaryState.RSI) {
      if (item.rsi != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, item.rsi!);
        mSecondaryMinValue = min(mSecondaryMinValue, item.rsi!);
      }
    } else if (secondaryState == SecondaryState.WR) {
      mSecondaryMaxValue = 0;
      mSecondaryMinValue = -100;
    } else if (secondaryState == SecondaryState.CCI) {
      if (item.cci != null) {
        mSecondaryMaxValue = max(mSecondaryMaxValue, item.cci!);
        mSecondaryMinValue = min(mSecondaryMinValue, item.cci!);
      }
    } else {
      mSecondaryMaxValue = 0;
      mSecondaryMinValue = 0;
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  /// Get the x-coordinate based on the index
  /// position * mPointWidth + mPointWidth / 2 to prevent the first and last bar from being displayed incorrectly
  /// @param position index value
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KLineEntity getItem(int position) {
    return entityList![position];
    // if (datas != null) {
    //   return datas[position];
    // } else {
    //   return null;
    // }
  }

  /// scrollX converted to TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  /// Get the minimum value of translation
  double getMinTranslateX() {
    final x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding;

    return x >= 0 ? 0.0 : x;
  }

  /// Calculate the value of x after long press, convert to index
  int calculateSelectedX(double selectX) {
    var mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }

    return mSelectedIndex;
  }

  /// TranslateX is converted to x in view
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }

  double _findMaxMA(List<double> a) {
    var result = double.minPositive;
    for (final i in a) {
      result = max(result, i);
    }

    return result;
  }

  double _findMinMA(List<double> a) {
    var result = double.maxFinite;
    for (final i in a) {
      result = min(result, i == 0 ? double.maxFinite : i);
    }

    return result;
  }

  ///二分查找当前值的index
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      final startValue = getX(start);
      final endValue = getX(end);

      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }

    final mid = start + (end - start) ~/ 2;
    final midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }
}
