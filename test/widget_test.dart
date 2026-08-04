import 'package:easy_data/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home displays the main content', (tester) async {
    await tester.pumpWidget(const EasyDataApp());

    expect(find.text('Easy Data'), findsOneWidget);
    expect(
      find.text('Crie gráficos profissionais em menos de 30 segundos.'),
      findsOneWidget,
    );
    expect(find.text('Criar gráfico'), findsOneWidget);
    expect(find.text('Sobre'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('Create chart button opens the data source bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const EasyDataApp());

    await tester.tap(find.text('Criar gráfico'));
    await tester.pumpAndSettle();

    expect(find.text('Como deseja inserir os dados?'), findsOneWidget);
    expect(find.text('Colar do Excel'), findsOneWidget);
    expect(find.text('Importar CSV'), findsOneWidget);
    expect(find.text('Digitar manualmente'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('A data source option opens the provisional editor', (
    tester,
  ) async {
    await tester.pumpWidget(const EasyDataApp());

    await tester.tap(find.text('Criar gráfico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colar do Excel'));
    await tester.pumpAndSettle();

    expect(find.text('Editor de Dados'), findsWidgets);
    expect(
      find.text('A entrada de dados será implementada em uma próxima sprint.'),
      findsOneWidget,
    );
  });
}
