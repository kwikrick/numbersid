# numbersid

A number sequence based sequencer for the SID.

Try it on-line: https://kwikrick.github.io/numbersid 

Project drived from floooh's excellent chips project.
Check it out: https://github.com/floooh/chips

## Building instructions

(Note: Derived from chips-test)

To build and run on Windows, OSX or Linux (exact versions of tools shouldn't matter):

Check prerequisites:

```bash
> python --version
Python 2.x or 3.x
> cmake --version
cmake version 3.x
```

NOTE: on Linux, additional dev packages need to be present for X11, GL and ALSA development.

Create a 'workspace' directory (which will be populated with additional dependencies),
clone and cd into ```numbersid```:

```bash
> mkdir workspace
> cd workspace
> git clone https://github.com/kwikrick/numbersid
> cd numbersid
```

Finally, build and run one of the emulators (for instance the Amstrad CPC):

```bash
> ./fips build
> ./fips list targets
> ./fips run numbersid
```

To get optimized builds for performance testing:

```bash
# on OSX:
> ./fips set config osx-make-release
> ./fips build
> ./fips run [target]

# on Linux
> ./fips set config linux-make-release
> ./fips build
> ./fips run [target]

# on Windows
> fips set config win64-vstudio-release
> fips build
> fips run [target]
```

To open project in IDE:
```bash
# on OSX with Xcode:
> ./fips set config osx-xcode-debug
> ./fips gen
> ./fips open

# on Windows with Visual Studio:
> ./fips set config win64-vstudio-debug
> ./fips gen
> ./fips open

# experimental VSCode support on Win/OSX/Linux:
> ./fips set config [linux|osx|win64]-vscode-debug
> ./fips gen
> ./fips open
```

To build the WebAssembly demos (Linux or OSX recommended here, Windows
might work too, but this is not well tested).

```bash
# first get ninja (on Windows a ninja.exe comes with the fips build system)
> ninja --version
1.8.2
# now install the emscripten toolchain, this needs a lot of time and memory
> ./fips setup emscripten
...
# from here on as usual...
> ./fips set config wasm-ninja-release
> ./fips build
...
> ./fips list targets
...
> ./fips run c64
...
```

## Many Thanks To:

- Andre Weissflog (floooh): https://github.com/floooh
