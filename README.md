# Draw IO Automata Parser

**EN** | [RU](README_RU.md)

## Description

This Bash-script allows you to find minimal automata for the represented one in diagram file `*.drawio`.

## Requirements

- Linux or WSL;
- Bash;
- `libxml-xpath-perl` apt-package installed (it will be installed automatically, if not already installed).

## Usage

1. Clone the repository inside Linux machine or WSL.

2. Create and save Draw IO diagram (look to example below).
   Rules:

   - Use ellipses for automata nodes;
   - You must create one and only one arrow without source;
   - All other arrows must have source and target (connect them to ellipses);
   - Add text to all arrows (except start arrow) with format `<variable name>/<variable value>`;

3. Run script:

    ```bash
    ./01_find_minimal.sh <file path>
    ```
   
   or:

    ```bash
    ./02_find_deterministic.sh <file path>
    ```

If you're having trouble with diagram created by yourself, try copying example diagram and modifying it instead.

## Example for script 1 - Find minimal automata

1. Create diagram:

   ![Input diagram](images_for_readme/script_01_example_01_input.svg)

2. Save diagram as `XML file (.drawio)` (very important to save in XML because file will be parsed that way).
   You can find this example in `./diagrams/examples` folder - file is called `script_01_example_01_input.drawio`.

3. Move file into `./diagrams` folder.

4. Run script:

   ```bash
   ./01_find_minimal.sh ./diagrams/examples/script_01_example_01_input.drawio
   ```

5. Wait for calculations and done! The result will be printed in the console:

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

6. **[By hand]** Based on output, we can now draw minimal automata:

   ![Result diagram](images_for_readme/script_01_example_01_result.svg)

## Example for script 2 - Find DFA from NFA

DFA - Deterministic Finite Automaton.

NFA - Nondeterministic Finite Automaton.

1. Create diagram:

   ![Input diagram](images_for_readme/script_02_example_01_input.png)

2. Save diagram as `XML file (.drawio)` (very important to save in XML because file will be parsed that way).
   You can find this example in `./diagrams/examples` folder - file is called `script_02_example_01_input.drawio`.

3. Move file into `./diagrams` folder.

4. Run script:

   ```bash
   ./02_find_deterministic.sh ./diagrams/examples/script_02_example_01_input.drawio
   ```

5. Wait for calculations and done! The result will be printed in the console:

   ```log
   Welcome to Automata Parser!
   Loading file diagrams/examples/11_example_input.drawio...
   Found 31 elements!
   Found 6 ellipses!
   Found 12 arrows!
   Found 11 label arrows!
   Start arrow found!
   No disconnected arrows found!
   Found 11 connected arrows!
   Loading file diagrams/examples/11_example_input.drawio: done!
   Parsing...
   Found last ellipse with value 6!
   -----------------------------------
   |         | a       | b       | l |
   -----------------------------------
   | {1}     | {2 5 6} | {2 5 6} | 0 |
   | {2 5 6} | {3 6}   | {∅}     | 1 |
   | {3 6}   | {3}     | {4}     | 1 |
   | {3}     | {3}     | {4}     | 0 |
   | {4}     | {5 6}   | {5 6}   | 0 |
   | {5 6}   | {6}     | {∅}     | 1 |
   | {6}     | {∅}     | {∅}     | 1 |
   -----------------------------------

   -----------------
   |   | a | b | l |
   -----------------
   | 1 | 2 | 2 | 0 |
   | 2 | 3 | - | 1 |
   | 3 | 4 | 5 | 1 |
   | 4 | 4 | 5 | 0 |
   | 5 | 6 | 6 | 0 |
   | 6 | 7 | - | 1 |
   | 7 | - | - | 1 |
   -----------------
   Parsing: done!
   ```

6. **[By hand]** Based on output, we can now draw deterministic automata:

   ![Result diagram](images_for_readme/script_02_example_01_result.png)

## Contribution

Feel free to contribute via [pull requests](https://github.com/Nikolai2038/draw-io-automata-parser/pulls) or [issues](https://github.com/Nikolai2038/draw-io-automata-parser/issues)!
