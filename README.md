# WSKrGUI

WSKrGUI is a lightweight graphical front end for the command line tool
**WSKr**. The interface is written in FreePascal using the Lazarus IDE.

## Requirements

* [Lazarus](https://www.lazarus-ide.org/) with the FreePascal compiler.
  Any recent version that can build 64‑bit Windows applications should work.
* The `wskr.exe` executable. The GUI expects it to be located in the same
  directory as the GUI executable at run time. If you do not already have it,
  grab the latest release from the [WSKr repository](https://github.com/sdunmall/WSKr)
  or build it from source.

## Building

1. Open `wskrgui.lpi` in Lazarus.
2. Choose **Run → Build** or press `Ctrl+F9` to compile the project. The
   resulting executable will appear in the project directory (by default the
   `Wskr GUI` folder).

Alternatively you can build the project from the command line using
`lazbuild`:

```sh
lazbuild "Wskr GUI/wskrgui.lpi"
```

The compiled program (`wskrgui.exe`) should reside next to `wskr.exe`.

## Usage

1. Make sure `wskr.exe` is placed alongside the GUI executable.
2. Launch `wskrgui.exe` and select the desired search action.
3. Enter a host range or paste a collection of host names.
4. Choose the information you wish to display (successes, failures, summary and
   timings) and click **Go**.
5. Results from `wskr.exe` are displayed in real time in the lower memo box.

The application merely builds a command line for `wskr.exe` based on your
options and displays the output.

