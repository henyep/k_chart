import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:k_chart/entity/info_window_entity.dart';
import 'package:k_chart/entity/k_line_entity.dart';
import 'package:k_chart/k_chart_widget.dart';
import 'package:k_chart/renderer/base_chart_painter.dart';
import 'package:k_chart/renderer/base_chart_renderer.dart';
import 'package:k_chart/renderer/main_renderer.dart';
import 'package:k_chart/renderer/secondary_renderer.dart';
import 'package:k_chart/renderer/vol_renderer.dart';
import 'package:k_chart/utils/date_format_util.dart';
import 'package:k_chart/utils/number_util.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(
    this.p1,
    this.p2,
    this.maxHeight,
    this.scale,
  );
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  final double selectY; //For TrendLine
  bool isRecordingCord = false; //For TrendLine
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer;
  BaseChartRenderer? mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  Color? upColor;
  Color? dnColor;
  Color? ma5Color;
  Color? ma10Color;
  Color? ma30Color;
  Color? volColor;
  Color? macdColor;
  Color? difColor;
  Color? deaColor;
  Color? jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint;
  late Paint selectorBorderPaint;
  late Paint nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required List<KLineEntity> datas,
    required double scaleX,
    required double scrollX,
    required bool isLongPass,
    required double selectX,
    required double xFrontPadding,
    required this.verticalTextAlignment,
    required bool isOnTap,
    required bool isTapShowInfoDialog,
    required MainState mainState,
    required bool volHidden,
    required SecondaryState secondaryState,
    this.sink,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
  }) : super(
          chartStyle,
          entityList: datas,
          scaleX: scaleX,
          scrollX: scrollX,
          isLongPress: isLongPass,
          isOnTap: isOnTap,
          isTapShowInfoDialog: isTapShowInfoDialog,
          selectX: selectX,
          mainState: mainState,
          volHidden: volHidden,
          secondaryState: secondaryState,
          xFrontPadding: xFrontPadding,
          isLine: isLine,
        ) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    final entities = entityList;
    if (entities != null && entities.isNotEmpty) {
      final item = entities.first;
      fixedLength = NumberUtil.getMaxDecimalLength(
        item.open,
        item.close,
        item.high,
        item.low,
      );
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      chartStyle,
      chartColors,
      scaleX,
      verticalTextAlignment,
      maDayList,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(
        mVolRect!,
        mVolMaxValue,
        mVolMinValue,
        mChildPadding,
        fixedLength,
        chartStyle,
        chartColors,
      );
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer = SecondaryRenderer(
        mSecondaryRect!,
        mSecondaryMaxValue,
        mSecondaryMinValue,
        mChildPadding,
        secondaryState,
        fixedLength,
        chartStyle,
        chartColors,
      );
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    final mBgPaint = Paint();
    final mBgGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: chartColors.bgColor,
    );
    final mainRect = Rect.fromLTRB(
      0,
      0,
      mMainRect.width,
      mMainRect.height + mTopPadding,
    );
    canvas.drawRect(
      mainRect,
      mBgPaint..shader = mBgGradient.createShader(mainRect),
    );

    if (mVolRect != null) {
      final volRect = Rect.fromLTRB(
        0,
        mVolRect!.top - mChildPadding,
        mVolRect!.width,
        mVolRect!.bottom,
      );
      canvas.drawRect(
        volRect,
        mBgPaint..shader = mBgGradient.createShader(volRect),
      );
    }

    if (mSecondaryRect != null) {
      final secondaryRect = Rect.fromLTRB(
        0,
        mSecondaryRect!.top - mChildPadding,
        mSecondaryRect!.width,
        mSecondaryRect!.bottom,
      );
      canvas.drawRect(
        secondaryRect,
        mBgPaint..shader = mBgGradient.createShader(secondaryRect),
      );
    }
    final dateRect = Rect.fromLTRB(
      0,
      size.height - mBottomPadding,
      size.width,
      size.height,
    );
    canvas.drawRect(
      dateRect,
      mBgPaint..shader = mBgGradient.createShader(dateRect),
    );
  }

  @override
  void drawGrid(Canvas canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (var i = mStartIndex; entityList != null && i <= mStopIndex; i++) {
      final curPoint = entityList?[i];
      if (curPoint == null) {
        continue;
      }

      final lastPoint = i == 0 ? curPoint : entityList![i - 1];
      final curX = getX(i);
      final lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(
        lastPoint,
        curPoint,
        lastX,
        curX,
        size,
        canvas,
      );
      mVolRenderer?.drawChart(
        lastPoint,
        curPoint,
        lastX,
        curX,
        size,
        canvas,
      );
      mSecondaryRenderer?.drawChart(
        lastPoint,
        curPoint,
        lastX,
        curX,
        size,
        canvas,
      );
    }

    if ((isLongPress || (isTapShowInfoDialog && isOnTap)) && isTrendLine) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine) {
      drawTrendLines(canvas, size);
    }
    canvas.restore();
  }

  @override
  void drawVerticalText(Canvas canvas) {
    final textStyle = getTextStyle(chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (entityList == null) {
      return;
    }

    final columnSpace = size.width / mGridColumns;
    final startX = getX(mStartIndex) - mPointWidth / 2;
    final stopX = getX(mStopIndex) + mPointWidth / 2;
    var x = 0.0;
    var y = 0.0;

    for (var i = 0; i <= mGridColumns; ++i) {
      final translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        final index = indexOfTranslateX(translateX);

        if (entityList?[index] == null) {
          continue;
        }
        final tp = getTextPainter(getDate(entityList![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    final index = calculateSelectedX(selectX);
    final point = getItem(index);

    final tp = getTextPainter(
      point.close.toString(),
      chartColors.crossTextColor,
    );
    final textHeight = tp.height;
    var textWidth = tp.width;

    const w1 = 5;
    const w2 = 3;
    var r = textHeight / 2 + w2;
    var y = getMainY(point.close);
    var isLeft = false;
    double x;

    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      final path = Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + w1 * 2, y + r);
      path.lineTo(textWidth + w1 * 2 + w2, y);
      path.lineTo(textWidth + w1 * 2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - w1 * 2 - w2;
      final path = Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    final dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + w1 * 2) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + w1 * 2) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    final baseLine = textHeight / 2;
    canvas.drawRect(
      Rect.fromLTRB(
        x - textWidth / 2 - w1,
        y,
        x + textWidth / 2 + w1,
        y + baseLine + r,
      ),
      selectPointPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        x - textWidth / 2 - w1,
        y,
        x + textWidth / 2 + w1,
        y + baseLine + r,
      ),
      selectorBorderPaint,
    );

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    // Long press to display the details of this data
    sink?.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    // Long press to display the data in the press
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      final index = calculateSelectedX(selectX);

      // TODO: FIX THIS
      data = getItem(index);
    }
    // Release to display the last piece of data
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine) {
      return;
    }
    // draw max and min
    var x = translateXtoX(getX(mMainMinIndex.toInt()));
    var y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //画右边
      final tp = getTextPainter(
        '-- ${mMainLowMinValue.toStringAsFixed(fixedLength)}',
        chartColors.minColor,
      );
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = getTextPainter(
        '${mMainLowMinValue.toStringAsFixed(fixedLength)} --',
        chartColors.minColor,
      );
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //画右边
      final tp = getTextPainter(
        '-- ${mMainHighMaxValue.toStringAsFixed(fixedLength)}',
        chartColors.maxColor,
      );
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      final tp = getTextPainter(
        '${mMainHighMaxValue.toStringAsFixed(fixedLength)} --',
        chartColors.maxColor,
      );
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!showNowPrice) {
      return;
    }

    if (entityList == null) {
      return;
    }

    final value = entityList!.last.close;
    var y = getMainY(value);

    // View display area boundary value drawing
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint.color = value >= entityList!.last.open
        ? chartColors.nowPriceUpColor
        : chartColors.nowPriceDnColor;

    // first draw the horizontal line
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space = chartStyle.nowPriceLineSpan + chartStyle.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + chartStyle.nowPriceLineLength, y),
        nowPricePaint,
      );
      startX += space;
    }
    // draw the background and text again
    final tp = getTextPainter(
      value.toStringAsFixed(fixedLength),
      chartColors.nowPriceTextColor,
    );

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = 0;
        break;
      case VerticalTextAlignment.right:
        offsetX = mWidth - tp.width;
        break;
    }

    final top = y - tp.height / 2;
    canvas.drawRect(
      Rect.fromLTRB(
        offsetX,
        top,
        offsetX + tp.width,
        top + tp.height,
      ),
      nowPricePaint,
    );
    tp.paint(canvas, Offset(offsetX, top));
  }

//For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    final index = calculateSelectedX(selectX);
    final paintY = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1
      ..isAntiAlias = true;
    final x = getX(index);
    trendLineX = x;

    final y = selectY;
    // getMainY(point.close);

    // k线图竖线
    canvas.drawLine(
      Offset(x, mTopPadding),
      Offset(x, size.height - mBottomPadding),
      paintY,
    );
    final paintX = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 1
      ..isAntiAlias = true;
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-mTranslateX, y),
      Offset(-mTranslateX + mWidth / scaleX, y),
      paintX,
    );
    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          height: 15.0 * scaleX,
          width: 15.0,
        ),
        paint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          height: 10.0,
          width: 10.0 / scaleX,
        ),
        paint,
      );
    }
    if (lines.isNotEmpty) {
      for (final element in lines) {
        final y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        final y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        final a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        final b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        final p1 = Offset(element.p1.dx, a);
        final p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
          p1,
          element.p2 == const Offset(-1, -1) ? Offset(x, y) : p2,
          Paint()
            ..color = Colors.yellow
            ..strokeWidth = 2,
        );
      }
    }
  }

  /// Draw the intersection line
  void drawCrossLine(Canvas canvas, Size size) {
    final index = calculateSelectedX(selectX);
    final point = getItem(index);
    final paintY = Paint()
      ..color = chartColors.vCrossColor
      ..strokeWidth = chartStyle.vCrossWidth
      ..isAntiAlias = true;
    final x = getX(index);
    final y = getMainY(point.close);
    // k线图竖线
    canvas.drawLine(
      Offset(x, mTopPadding),
      Offset(x, size.height - mBottomPadding),
      paintY,
    );

    final paintX = Paint()
      ..color = chartColors.hCrossColor
      ..strokeWidth = chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // k线图横线
    canvas.drawLine(
      Offset(-mTranslateX, y),
      Offset(-mTranslateX + mWidth / scaleX, y),
      paintX,
    );
    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          height: 2.0 * scaleX,
          width: 2.0,
        ),
        paintX,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          height: 2.0,
          width: 2.0 / scaleX,
        ),
        paintX,
      );
    }
  }

  TextPainter getTextPainter(String text, Color? color) {
    color ??= chartColors.defaultTextColor;

    final span = TextSpan(text: text, style: getTextStyle(color));
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    return tp;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
          date ?? DateTime.now().millisecondsSinceEpoch,
        ),
        mFormats,
      );

  double getMainY(double y) => mMainRenderer.getY(y);

  /// Whether the point is in SecondaryRect
  bool isInSecondaryRect(Offset point) {
    return mSecondaryRect?.contains(point) ?? false;
  }

  /// Whether the point is in MainRect
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }

  static double get maxScrollX => BaseChartPainter.maxScrollX;
}
