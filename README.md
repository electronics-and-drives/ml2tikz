# ml2tikz

*maskLayout* to *tikzpicture* converter for Cadence Virtuoso

## Description

Cadence SKILL function, which can be used to create a *tikzpicture* of a *maskLayout*. This is especially useful for theses, publications and presentation.

## Installation

The function can be used by loading the SKILL file *ml2tikz.il* in Cadence Virtuoso:

``` scheme
(load "ml2tikz.il")
```

A more convenient way might be to add this load command in the `.cdsinit`.

## Usage

### Command Interpreter Window

The function ML2TIKZ must be invoked in the Command Interpreter Window (CIW).

``` scheme
(ML2TIKZ ?sOutDir "~/myExports"  ?sLayersLatexFile "~/myLayerDefinition.tex")
```

The above shown example function call creates a *tikzpicture* of the maskLayout which is shown in the foreground in a layout editor.
The result will be written to the directory `"~/myExports"`, which must be read- and writable.
There, all files will be created.
The path to this directory will be returned by the function.

The function must be provided with a *.tex* file (`"~/myLayerDefinition.tex"` in the example above) where all layer purpose pairs (LPPs) to be considered in the *tikzpicture* must be defined.

Only LPPs, separated with a underscore, in  a `\tikzstyle` command, are considered for export, e.g

``` tex
\tikzstyle{Metal1_drawing}=[draw=blue,fill=blue, fill opacity=0.5]
```

TikZ offers several possibilities to define different styles, e.g. outline, filling, opacity, patterns et cetera.
If you are not familiar with TiKZ, take a look at the [manual](https://www.ctan.org/pkg/pgf).

The order of `\tikzstyle` commands in the Layers Latex file is identical with the order how the layers are drawn within the *tikzpicture*, so make sure that the order is meaningful ,e.g. define Poly before Metal 1 et cetera.

In this *.tex* file additional definitions e.g. other usepackages must be defined as well.

In the result directory a *Makefile* is created, which contains the compilation commands needed for compiling the *pdf*.
This *Makefile* can be executed using 

``` bash
make
```

### GUI

This tool is added to the Layout Editor under *Export* in the menu bar. If the tool is invoked, a GUI will show up:

![](fig/ml2tikz_gui.png)

There, some [parameters](#Parameters) can be specified. By pressing *OK* or *Apply* the *tikzpicture* is created.

The field *Open With* can be used to specify the tool which will be used to open the resulting directory (e.g. *thunar* , *nautilus* , *xterm*, etc.).
If this value is not specified, the resulting directory is shown in a dialog box.


## Parameters
The function ML2TIKZ has several keyword parameters:

`oCellView`

Cellview to be be exported. 
If this parameter is not provided, the current cellview in the foreground `(geGetWindowCellView)` is used.

`sOutDir`

The output directory, where the *tikzpicture* will be created. 
It must be read- and writable. 
If this parameter is not provided the current directory (.) will be used.

`sLayersLatexFile`

A path to a LaTeX file, where all Layer Purpose Pairs (LPPs) considered for export must be defined.

` sLatexCompiler `

The LaTeX compiler, which should be used. If this parameter is not provided *pdflatex* will be used.

` bBox `

Bounding Box, which is used for export.

`nGridSize`

The grid side of the *tikzpicture* in centimeters. If this value is not provided, 1cm is used as a default value.

`nMargin`

The margin of the *tikzpicture*. If this value is not provided, no margin is drawn.

`bDebug`

If this parameter is true, the [intermediate cellviews](#implementation-details) are not deleted at the end.

`xShapesPerFile`

Due to limited memory, a *tikzpicture* can contain only a limited number of shapes. This parameter can be used to control the maximum number of shapes that are within one *tikzpicture*. If the maskLayout to be exported contains more shapes that specified by this parameter, the maskLayout will be splitted automatically in several TeX files, s.t. the maximum number of shapes per single file is not exceeded. The compilation results of the individual TeX files will be merged in a final *tikzpicture*.

` bSplitLayers `

If this parameter is true, additional *tikzpictures* will be created, which contain only single layers.

` bMake `

If this parameter is set true, `make` is executed automatically.

## Examples

In the directory *examples* an example of an exported nand2 logic gate is added.

![](fig/nand2.png)

## Implementation Details

The implementation of the function is rather simple. 
The function will first create a copy of the maskLayout. 
Then this copy will be flattened. Another new empty layout is created. 
In this new layout all shapes of interest are copied in merged.

## Dependencies

Needed LaTeX usepackages:

+ [graphicx](https://ctan.org/pkg/graphicx)  
+ [tikz](https://www.ctan.org/pkg/pgf)
