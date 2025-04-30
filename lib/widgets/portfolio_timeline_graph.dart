import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class PortfolioTimelineGraph extends StatefulWidget {
  final List<Map<String, dynamic>> portfolioData;
  final double totalPortfolioValue;
  final double? previousTotalValue;
  final double? height;
  final bool showTimeRangeSelector;
  final bool showTitle;
  
  const PortfolioTimelineGraph({
    super.key,
    required this.portfolioData,
    required this.totalPortfolioValue,
    this.previousTotalValue,
    this.height, // Make height optional
    this.showTimeRangeSelector = true, // Make time selector optional
    this.showTitle = true, // Make title optional
  });

  @override
  _PortfolioTimelineGraphState createState() => _PortfolioTimelineGraphState();
}

class _PortfolioTimelineGraphState extends State<PortfolioTimelineGraph> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  String _selectedTimeRange = '1W'; // Default to 1 week
  final List<String> _timeRanges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
  
  List<FlSpot> _spots = [];
  double _minY = 0;
  double _maxY = 0;
  List<Color> _gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];
  
  // For tooltip
  int _touchedIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    
    _generateChartData();
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(covariant PortfolioTimelineGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portfolioData != widget.portfolioData ||
        oldWidget.totalPortfolioValue != widget.totalPortfolioValue) {
      _generateChartData();
      _animationController.reset();
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _generateChartData() {
    // Generate realistic timeline data based on selected time range
    // In a real app, this would come from historical data
    setState(() {
      _spots = [];
      
      // Number of data points based on time range
      int pointCount = 0;
      switch (_selectedTimeRange) {
        case '1D': pointCount = 24; break; // Hourly
        case '1W': pointCount = 7; break;  // Daily
        case '1M': pointCount = 30; break; // Daily
        case '3M': pointCount = 12; break; // Weekly
        case '1Y': pointCount = 12; break; // Monthly
        case 'ALL': pointCount = 24; break; // Monthly or quarterly
      }
      
      // Generate data with realistic trends
      double currentValue = widget.previousTotalValue ?? 
                           (widget.totalPortfolioValue * 0.8); // Start lower if no previous
      double targetValue = widget.totalPortfolioValue;
      
      double volatility = 0.03; // 3% volatility
      math.Random random = math.Random();
      
      // Data generation with overall trend towards current value
      for (int i = 0; i < pointCount; i++) {
        // Create a gradual trend towards the target with some randomness
        double progress = i / (pointCount - 1);
        double trendValue = currentValue + (targetValue - currentValue) * progress;
        
        // Add random noise that decreases as we get closer to current time
        double randomFactor = (1 - (progress * 0.8)) * volatility;
        double noise = (random.nextDouble() * 2 - 1) * randomFactor * trendValue;
        
        double value = trendValue + noise;
        value = value.clamp(0, double.infinity); // Ensure no negative values
        
        _spots.add(FlSpot(i.toDouble(), value));
      }
      
      // Calculate min and max for Y axis with some padding
      if (_spots.isNotEmpty) {
        _minY = _spots.map((spot) => spot.y).reduce(
            (a, b) => a < b ? a : b) * 0.95;
        _maxY = _spots.map((spot) => spot.y).reduce(
            (a, b) => a > b ? a : b) * 1.05;
      }
      
      // Set gradient colors based on overall performance
      double performance = (targetValue - currentValue) / currentValue;
      if (performance > 0) {
        _gradientColors = [
          Color(0xFF00BFA5), // Teal
          Color(0xFF00E676), // Green
        ];
      } else {
        _gradientColors = [
          Color(0xFFFF7043), // Orange
          Color(0xFFE57373), // Red-ish
        ];
      }
    });
  }
  
String _getBottomTitle(double value, int pointCount) {
  // Return appropriate time labels based on the selected time range
  final DateTime now = DateTime.now();
  late DateTime date;
  
  switch (_selectedTimeRange) {
    case '1D':
      // For 1 day, show hours
      date = now.subtract(Duration(hours: (pointCount - value.toInt() - 1)));
      return DateFormat('ha').format(date);
    case '1W':
      // For 1 week, show day names
      date = now.subtract(Duration(days: (pointCount - value.toInt() - 1)));
      return DateFormat('E').format(date);
    case '1M':
      // For 1 month, show dates
      date = now.subtract(Duration(days: (pointCount - value.toInt() - 1)));
      return DateFormat('d').format(date);
    case '3M':
      // For 3 months, show weeks/months
      date = now.subtract(Duration(days: (pointCount - value.toInt() - 1) * 7));
      return DateFormat('MM/dd').format(date);
    case '1Y':
      // For 1 year, show months
      date = DateTime(now.year, now.month - (pointCount - value.toInt() - 1));
      return DateFormat('MMM').format(date);
    case 'ALL':
    default:
      // For all time, show quarters/years
      date = DateTime(now.year - ((pointCount - value.toInt() - 1) ~/ 4), 
                      now.month - ((pointCount - value.toInt() - 1) % 4) * 3);
      return DateFormat('MMM').format(date);
  }
}
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available height
        final availableHeight = widget.height ?? 
          (constraints.maxHeight.isFinite ? constraints.maxHeight : 240);
        
        // Calculate component heights based on what's shown
        final timeRangeSelectorHeight = widget.showTimeRangeSelector ? 40.0 : 0.0;
        final titleSectionHeight = widget.showTitle ? 52.0 : 0.0;
        final chartHeight = availableHeight - timeRangeSelectorHeight - titleSectionHeight;
        
        return Column(
          mainAxisSize: MainAxisSize.min, // Don't take more space than needed
          children: [
            // Time range selector - only shown if enabled
            if (widget.showTimeRangeSelector)
              SizedBox(
                height: timeRangeSelectorHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _timeRanges.map((range) {
                        bool isSelected = range == _selectedTimeRange;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeRange = range;
                              _generateChartData();
                              _animationController.reset();
                              _animationController.forward();
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Color.fromARGB(255, 27, 121, 121).withOpacity(0.7) 
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Color.fromARGB(255, 27, 121, 121) 
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              range,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            
            // Chart card with dynamic height
            Container(
              height: chartHeight + (widget.showTitle ? titleSectionHeight : 0),
              padding: EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: Colors.blueGrey.shade900.withOpacity(0.7),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title with performance indicator - only if showing title
                  if (widget.showTitle) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Portfolio Performance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.previousTotalValue != null)
                          _buildPerformanceIndicator(),
                      ],
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Current value
                    Text(
                      '\$${widget.totalPortfolioValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                  ],
                  
                  // Chart - using all remaining space
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return LineChart(
                          _mainLineChartData(_animation.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildPerformanceIndicator() {
    final double change = widget.totalPortfolioValue - (widget.previousTotalValue ?? 0);
    final double percentChange = widget.previousTotalValue != null && widget.previousTotalValue! > 0
        ? (change / widget.previousTotalValue!) * 100
        : 0;
    
    final bool isPositive = change >= 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPositive ? Colors.green : Colors.red,
            size: 14,
          ),
          SizedBox(width: 2),
          Text(
            '${isPositive ? "+" : ""}${percentChange.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  LineChartData _mainLineChartData(double animationPercent) {
    // Apply animation to spots
    final animatedSpots = _spots.map((spot) {
      return FlSpot(spot.x, spot.y * animationPercent);
    }).toList();
    
    // The number of points for labeling
    final pointCount = animatedSpots.length;
    
    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.8),
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final date = _getTooltipDate(spot.x.toInt(), pointCount);
              return LineTooltipItem(
                '$date\n\$${spot.y.toStringAsFixed(2)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (touchResponse?.lineBarSpots != null && 
                touchResponse!.lineBarSpots!.isNotEmpty) {
              _touchedIndex = touchResponse.lineBarSpots![0].x.toInt();
            } else {
              _touchedIndex = -1;
            }
          });
        },
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: Colors.white.withOpacity(0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: _gradientColors[0],
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (_maxY - _minY) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // Increase reserved space for x-axis labels
            interval: animatedSpots.length > 10 ? 
                    (animatedSpots.length / 5).floorToDouble() : 1, // Show fewer labels on crowded charts
            getTitlesWidget: (value, meta) {
              // Only show labels at calculated intervals
              if (value.toInt() % meta.appliedInterval.toInt() == 0) {
                if (value >= 0 && value < animatedSpots.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getBottomTitle(value, pointCount),
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              // Only show a few labels to avoid crowding
              if (value == _minY || 
                  value == _maxY || 
                  value == (_minY + _maxY) / 2) {
                return Container(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    '\$${value.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              }
              return Container();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: animatedSpots.length.toDouble() - 1,
      minY: _minY,
      maxY: _maxY,
      lineBarsData: [
        LineChartBarData(
          spots: animatedSpots,
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: _gradientColors.map((color) => color.withOpacity(0.3)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
  
  String _getTooltipDate(int spotIndex, int pointCount) {
    final DateTime now = DateTime.now();
    
    switch (_selectedTimeRange) {
      case '1D':
        final date = now.subtract(Duration(hours: (pointCount - spotIndex - 1)));
        return DateFormat('h:mm a').format(date);
      case '1W':
        final date = now.subtract(Duration(days: (pointCount - spotIndex - 1)));
        return DateFormat('E, MMM d').format(date);
      case '1M':
        final date = now.subtract(Duration(days: (pointCount - spotIndex - 1)));
        return DateFormat('MMM d').format(date);
      case '3M':
        final date = now.subtract(Duration(days: (pointCount - spotIndex - 1) * 7));
        return DateFormat('MMM d').format(date);
      case '1Y':
        final date = DateTime(now.year, now.month - (pointCount - spotIndex - 1));
        return DateFormat('MMM yyyy').format(date);
      case 'ALL':
      default:
        final date = DateTime(now.year - ((pointCount - spotIndex - 1) ~/ 4), 
                    now.month - ((pointCount - spotIndex - 1) % 4) * 3);
        return DateFormat('MMM yyyy').format(date);
    }
  }
}