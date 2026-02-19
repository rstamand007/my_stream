import 'package:logger/logger.dart';

/// Global logger instance for the application
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Logger for production builds with minimal output
final productionLogger = Logger(
  printer: SimplePrinter(colors: false),
  level: Level.warning,
);
