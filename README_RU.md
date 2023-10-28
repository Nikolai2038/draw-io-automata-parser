# Draw IO Automata Parser

[EN](README.md) | **RU**

## Описание

Данный Bash-скрипт позволяет найти минимальный автомат из автомата, нарисованного на диаграмме в файле `*.drawio`.

## Требования

- Linux или WSL;
- Bash;
- `libxml-xpath-perl` apt-пакет (он будет установлен автоматически, если ещё не установлен).

## Использование

1. Склонировать репозиторий:

2. Создать и сохранить диаграмму Draw IO (смотреть пример ниже).
   Правила:

   - Использовать эллипсы для узлов автомата;
   - Обязательно должна быть одна и только одна стрелка без начала;
   - Все остальные стрелки должны иметь начало и конец (соединяют эллипсы);
   - У всех стрелок (кроме начальной) должен быть текст формата `<название переменной>/<значение переменной>`;

3. Выполнить сам скрипт:

    ```bash
    ./01_find_minimal.sh <путь к файлу>
    ```

Если у Вас возникают проблемы создания диаграммы с нуля, попробуйте скопировать файл примера и изменить его под себя.

## Пример

1. Создадим диаграмму:

   ![Исходная диаграмма](images/01_input_diagram.svg)

2. Сохраним диаграмму как `XML-файл (.drawio)` (очень важно сохранить именно в XML, потому что файл будет парсится именно по формату XML).
   Вы можете найти этот пример в директории `./diagrams/examples` - файл называется `01_example_input.drawio`.

3. Переместим файл в директорию `./diagrams`.

4. Выполним сам скрипт:

   ```bash
   ./01_find_minimal.sh ./diagrams/examples/01_example_input.drawio
   ```

5. Подождём, пока вычисления завершатся и всё! Результат будет выведен в консоль:

   ```log
   Welcome to Automata Parser!
   Loading file ./diagrams/01_example_input.drawio...
   Found 21 elements!
   Found 6 ellipses!
   Found 13 arrows!
   Found 0 label arrows!
   Start arrow found!
   No disconnected arrows found!
   Found 12 connected arrows!
   Loading file ./diagrams/01_example_input.drawio: done!
   Parsing...
   Calculate data for ellipse with value 1!
   - Calculate data for arrow with value b/1!
   - Calculate data for arrow with value a/0!
   Calculate data for ellipse with value 2!
   - Calculate data for arrow with value a/1!
   - Calculate data for arrow with value b/1!
   Calculate data for ellipse with value 3!
   - Calculate data for arrow with value a/0!
   - Calculate data for arrow with value b/1!
   Calculate data for ellipse with value 4!
   - Calculate data for arrow with value b/0!
   - Calculate data for arrow with value a/1!
   Calculate data for ellipse with value 5!
   - Calculate data for arrow with value a/0!
   - Calculate data for arrow with value b/1!
   Calculate data for ellipse with value 6!
   - Calculate data for arrow with value b/1!
   - Calculate data for arrow with value a/1!
   Calculate K0...
   - K0 = { A0={1}, B0={2}, C0={3}, D0={4}, E0={5}, F0={6} }
   Calculate K1...
   - K1 = { A1={1,3,5}, B1={2,6}, C1={4} }
   Calculate K2...
   - K2 = { A2={1,5}, B2={2,6}, C2={3}, D2={4} }
   Calculate K3...
   - K3 = { A3={1,5}, B3={2,6}, C3={3}, D3={4} }
   ================================================================================
   Result:
   ================================================================================
   S = { 1, 2, 3, 4, 5, 6 }
   u0 = 1

   ----------------------------------------------------------------
   |      | λ    | λ    | δ    | δ    | K1   | K1   | K2   | K2   |
   |      | a    | b    | a    | b    | a    | b    | a    | b    |
   ----------------------------------------------------------------
   | 1    | 0    | 1    | 2    | 5    | B1   | A1   | B2   | A2   |
   | 2    | 1    | 1    | 3    | 1    | A1   | A1   | C2   | A2   |
   | 3    | 0    | 1    | 4    | 5    | C1   | A1   | D2   | A2   |
   | 4    | 1    | 0    | 6    | 4    | B1   | C1   | B2   | D2   |
   | 5    | 0    | 1    | 2    | 5    | B1   | A1   | B2   | A2   |
   | 6    | 1    | 1    | 3    | 1    | A1   | A1   | C2   | A2   |
   ----------------------------------------------------------------

   K0 = { A0={1}, B0={2}, C0={3}, D0={4}, E0={5}, F0={6} }
   K1 = { A1={1,3,5}, B1={2,6}, C1={4} }
   K2 = { A2={1,5}, B2={2,6}, C2={3}, D2={4} }
   K3 = { A3={1,5}, B3={2,6}, C3={3}, D3={4} }
   K3 == K2 == K

   Smin = { A, B, C, D }
   u0min = A

   ------------------------------------
   |      | λmin | λmin | δmin | δmin |
   |      | a    | b    | a    | b    |
   ------------------------------------
   | A    | 0    | 1    | B    | A    |
   | B    | 1    | 1    | C    | A    |
   | C    | 0    | 1    | D    | A    |
   | D    | 1    | 0    | B    | D    |
   ------------------------------------
   ================================================================================
   Parsing: done!
   ```

6. **[Вручную]** Основываясь на полученном результате, мы теперь можем нарисовать минимальный автомат:

   ![Итоговая диаграмма](images/01_result_diagram.svg)

## Развитие

Не стесняйтесь участвовать в развитии репозитория, используя [pull requests](https://github.com/Nikolai2038/draw-io-automata-parser/pulls) или [issues](https://github.com/Nikolai2038/draw-io-automata-parser/issues)!
