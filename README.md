# ml2tikz

*maskLayout* to *tikzpicture* converter for Cadence Virtuoso

## Description

Cadence SKILL function, which can be used to create a *tikzpicture* of a *maskLayout*. 
This is especially useful for theses, publications and presentation.

## Example Usage

The function can be used by loading the SKILL file, enclosed in in this repository in Cadence Virtuoso.
```
load("ml2tikz.il")
```

A more convenient way might be to add this load command in the `.cdsinit`.

Afterwards the function ML2TIKZ can be invoked in the Command Interpreter Window (CIW).

```
(ML2TIKZ ?sOutDir "~/myExports"  ?sLayersLatexFile "~/myLayerDefinition.tex")
```
The above shown example function call creates a *tikzpicture* of the current active maskLayout in Virtuoso.
The result will be written to the directory `"~/myExports"`, which must be read. and writable.
There a new directory will be created where a *.tex* file with the *tikzpicture* of the maskLayout is created.
The path to this directory will be returned by the function.
The directory's name will consist of the library- , cell- and view name plus a additional time stamp.

The function must be provided with a *.tex* file (`"~/myLayerDefinition.tex"` in the example above) where all layer purpose pairs (LPPs) to be considered in the *tikzpicture* must be defined.

Only LPPs, seperated with a underscore, in  a `\tikzstyle` command, are considered for export, e.g

```
\tikzstyle{Metal1_drawing}=[draw=blue,fill=blue, fill opacity=0.5]
```

TikZ offers several possibilities to define different styles, e.g. outline, filling, opacities, patterns et cetera.
If you are not familiar with TiKZ, take a look at the [manual](https://www.ctan.org/pkg/pgf).

The order of `\tikzstyle` commands in the Layers Latex file is identical with the order how the layers are drawn within the *tikzpicture*, so make sure that the order is meaningful ,e.g. define Poly before Metal 1 et cetera.

In this *.tex* file additional definitions e.g. other usepackages must be defined as well.

## Function Parameters
The function ML2TIKZ has several keyword parameters

``` sOutDir ```

The output directory, where the *tikzpicture* will be created. 
It must be read- and writable. 
If this parameter is not provided the current directory (.) will be used.

``` sLayersLatexFile ```

A path to a LaTeX file, where all Layer Purpose Pairs (LPPs) considered for export must be defined.



## Implementation Details

The implementation of the function is rather simple. 
The function will first create a copy of the maskLayout. 
Then this copy will be flattened. Another new empty layout is created. 
In this new layout all shapes of interest are copied in merged.
