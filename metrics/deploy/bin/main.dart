import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:deploy/doctor/doctor_command.dart';
import 'package:deploy/deploy/deploy_command.dart';

Future main(List<String> arguments) async {
  final runner = CommandRunner("metrics", "Metrics installer.")
    ..addCommand(DoctorCommand())
    ..addCommand(DeployCommand());
  try {
    await runner.run(arguments);
    exit(0);
  } catch (error) {
    exit(1);
  }
}
