part of 'export_import_bloc.dart';

abstract class ExportImportEvent extends Equatable {
  const ExportImportEvent();
}

class ExportDataEvent extends ExportImportEvent {
  final String format;
  const ExportDataEvent({this.format = 'json'});

  @override
  List<Object?> get props => [format];
}

class ImportDataEvent extends ExportImportEvent {
  @override
  List<Object?> get props => [];
}
