import 'package:logger/logger.dart';
import 'package:logger_flutter/logger_flutter.dart';


class ExtendedLogOutput extends ConsoleOutput {
  @override
  void output(OutputEvent event) {
    super.output(event);
    LogConsole.add(event);
  }
}


Logger createLogger() => Logger(
  level: Level.debug,  // TODO: настройка извне
  output: ExtendedLogOutput(),
  filter: ProductionFilter(),
);
