/// A class that represents the coverage converter arguments.
class CoverageConverterArguments {
  /// An input file path containing the specific coverage report.
  final String inputFilePath;

  /// An output file path where to write the converted coverage report.
  final String outputFilePath;

  /// Creates a [CoverageConverterArguments].
  ///
  /// The [inputFilePath] and the [outputFilePath] must not be null.
  CoverageConverterArguments({
    this.inputFilePath,
    this.outputFilePath,
  }) {
    ArgumentError.checkNotNull(inputFilePath, 'inputFileName');
    ArgumentError.checkNotNull(outputFilePath, 'outputFilePath');
  }
}
