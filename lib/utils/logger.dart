import 'package:logger/logger.dart';
import 'package:logger_flutter/logger_flutter.dart';

class ExtendedLogOutput extends ConsoleOutput {
  @override
  void output(OutputEvent event) {
    super.output(event);
    LogConsole.add(event);
  }
}

Logger createLogger([Level level = Level.debug]) => Logger(
      level: level,
      output: ExtendedLogOutput(),
      filter: ProductionFilter(),
    );
