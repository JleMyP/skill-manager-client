import 'package:logger/logger.dart';
import 'package:logger_flutter/logger_flutter.dart';


class ExtendedLogOutput extends ConsoleOutput {
  @override
  void output(OutputEvent event) {
    super.output(event);
    LogConsole.add(event);
  }
}


Logger createLogger() {
  var filter = ProductionFilter();
  filter.level = Level.debug;  // TODO: настройка извне
  var logger = Logger(
    level: Level.debug,
    output: ExtendedLogOutput(),
    filter: filter,
  );
   return logger;
}
