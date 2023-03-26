/*=============================================================================*
*
*   EDml2TikZ
*
*   Purpose:    maskLayout to tikzpicture converter
*
*   Author:     Matthias Schweikardt
*   Email:      matthias.schweikardt@reutlingen-university.de
*
*   Lint: IQ score is 100 (best is 100) 
*         {sklint ?file "EDml2TikZ.il"}
*
*   Globals:
*    - Symbols:
*     o EDml2TikZ
*    - Forms and Fields:
*     o EDml2TikZLayoutForm
*    - Functions:
*     o EDml2TikZ
*
*   Revision:   2019-03-29 Created
*               2019-04-16 Added GUI
*               2019-06-05 Added margin
*               2019-12-24 refractured/output dir by user/bBox
*               2022-08-06 Use advanced boolean engine
*               2022-09-25 Add layout menu items to separate file
*               2023-03-26 Improved comments
*
*   Copyright 2023, Reutlingen University, Electronics & Drives 
*
*   Permission is hereby granted, free of charge, to any person obtaining a 
*   copy of this software and associated documentation files (the "Software"), 
*   to deal in the Software without restriction, including without limitation 
*   the rights to use, copy, modify, merge, publish, distribute, sublicense, 
*   and/or sell copies of the Software, and to permit persons to whom the 
*   Software is furnished to do so, subject to the following conditions:
*
*   The above copyright notice and this permission notice shall be included in 
*   all copies or substantial portions of the Software.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
*   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
*   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
*   DEALINGS IN THE SOFTWARE.
*
*=============================================================================*/

;FUNCTION
; EDml2TikZ
;
;Description: see README.md
;
(defun 
  EDml2TikZ
  (
    @key
    (oCellView (geGetWindowCellView))
    (sOutDir "./")
    (sLayersLatexFile nil)
    (sLatexCompiler "pdflatex")   
    (nGridSize 1.0)
    (bDebug nil)
    (bAbe t)
    (xParallelABEruns 1)
    (xShapesPerFile 1000)
    (xLevels 32)
    (bSplitLayers nil)
    (bBox nil)
    (bMake t)
    (nMargin 0)
    (bGraphicalMode nil)
  )

  (let (dpl)

    xParallelABEruns ; for lint

    (unless (dplp EDml2TikZ.dpl)
      (putpropq (quote EDml2TikZ) (list nil) dpl)
    );unless

  ; The whole data of the tool is stored in the disembodied property list dpl. 
  ; This dpl is stored in the property list of the  symbol 'EDml2TikZ'. 
  ; The dpl can be retrieved by'EDml2TikZ.dpl'. 
  ; The structure of the dpl is shown below:
  ;
  ; dpl
  ; |
  ; +view                                   fields and forms are described below
  ; |   |
  ; |   +forms
  ; |   |   |
  ; |   |   +outDirFileSelectorField (1.1)
  ; |   |   |
  ; |   |   +latexFileFileSelectorField (1.2)
  ; |   |   |
  ; |   |   +levelsIntField (1.3)
  ; |   |   |
  ; |   |   +gridSizeFloatForm (1.4)
  ; |   |   |
  ; |   |   +marginFloatForm (1.5)
  ; |   |   |
  ; |   |   +latexCompilerStringField (1.6)
  ; |   |   |
  ; |   |   +abeBooleanButton (1.7)
  ; |   |   |
  ; |   |   +parallelABEruns (1.8)
  ; |   |   |
  ; |   |   +shapesPerFileIntField (1.9)
  ; |   |   |
  ; |   |   +openWithStringField (1.10)
  ; |   |   |
  ; |   |   +splitLayerBooleanButton (1.11)
  ; |   |   |
  ; |   |   +makeBooleanButton (1.12)
  ; |   |   |
  ; |   |   +debugBooleanButton (1.13)
  ; |   |   |
  ; |   |   +EDml2TikZFormLayout (1)
  ; |   |
  ; |   +callbacks
  ; |       |
  ; |       +fExecuteMl2TikZ
  ; |
  ; +temp  
  ; |   |
  ; |   +sStartTime               string, time stamp when the tool os started
  ; |
  ; +model
  ; |   |
  ; |   +cv                       db-obj, cellview database object of the 
  ; |   |                                  layout to be exported
  ; |   |
  ; |   +sLayersLatexFile         string, path to the LaTeX file where all
  ; |   |                                  layers are defined
  ; |   |
  ; |   +sOutDir                  string, path to the output directory
  ; |   |
  ; |   +bAbe                     bool, indicated if the Advanced Boolean
  ; |   |                                Engine (ABE) is used
  ; |   |     
  ; |   +xParallelABEruns         int, number of parallel ABE runs
  ; |   | 
  ; |   +xLevels                  int, number of levels of hierarchy through
  ; |   |                              which the layout is exported
  ; |   |                               
  ; |   +xShapesPerFile           int, max- number of shapes that are
  ; |   |                              exported to a *.tex* file
  ; |   |
  ; |   +sLatexCompiler           string, name of the LaTeX compiler
  ; |   |
  ; |   +bMake                    bool, execute *make* after export
  ; |   |
  ; |   +bDebug                   bool, enable debug mode, i.e., the
  ; |   |                                intermediate cellviews are not 
  ; |   |                                deleted after export
  ; |   |
  ; |   +nGridSize               float, grid size in cm in the *.tex* file
  ; |   |
  ; |   +bSplitLayers            bool, split the layers in different *.tex*
  ; |   |                               files
  ; |   |
  ; |   +nMargin                float, margin between the layout and the 
  ; |   |                              border of the resulting PDF
  ; |   | 
  ; |   +bBox                   list, bounding box of the layout to be exported
  ; |   | 
  ; |   +oFlattenCellView       db-obj, cellview database object of the
  ; |   |                                flattened layout  
  ; |   | 
  ; |   +oCombinedCellView      db-obj, cellview database object of the
  ; |   |                                combined layout    
  ; |   | 
  ; |   +lLayers                list, list of layers to be exported
  ; |   |
  ; |   +xNumOfShapes           int, shape counter
  ; |   | 
  ; |   |  
  ; |   |                        lambda functions are explained below
  ; |   +fCheckInout
  ; |   |
  ; |   +fWriteTikZwithABE
  ; |   |
  ; |   +fWriteTikZ 
  ; |   |
  ; |   +fReadInLayersLatexFile   
      
    (setq dpl EDml2TikZ.dpl)

    (unless dpl->model

      dpl->model = (list nil)

      ;LAMBDA FUNCTION
      ; fReadInLayersLatexFile
      ;
      ;Description:
      ; Read all layers to be exported from a *.tex* file
      ;
      ;Parameters:
      ;  dpl       dpl, disembodied property list of the tool
      ; 
      ;Return:
      ; lLayers    list, list of layers
      ;
      (putpropq 
        dpl->model
        (lambda (dpl)
          (let (s pPort)

            dpl->model->lLayers = nil

            (when 
              (and
                (stringp dpl->model->sLayersLatexFile)
                (isFile dpl->model->sLayersLatexFile)
                (isReadable dpl->model->sLayersLatexFile)
              );and

              (putpropq 
                dpl->model   
                (car (last (parseString dpl->model->sLayersLatexFile "/")))
                sLayersLatexFileName  
              );putpropq

              (setq pPort (infile dpl->model->sLayersLatexFile))

              (while (gets s pPort)

                (rexCompile "[ ]*\\tikzstyle{[ ]*\\([\\|a-zA-Z_0-9]*\\)[ ]*}.*")

                (when 
                  (and
                    (rexExecute s)
                    (equal (length (parseString (rexSubstitute "\\1") "|")) 2)
                  );and
                  (putpropq 
                    dpl->model
                    (cons
                      (parseString (rexSubstitute "\\1") "|")
                      dpl->model->lLayers
                    );cons
                    lLayers
                  );putpropq
                );when
              );while

              (putpropq 
                  dpl->model
                (reverse dpl->model->lLayers)
                lLayers
              );putpropq  
            );when
            dpl->model->lLayers    
          );let
        );lambda
        fReadInLayersLatexFile
      );putpropq


      ;LAMBDA FUNCTION
      ; fWriteTikZ
      ;
      ;Description:
      ; Export the layout as TikZ
      ;
      ;Parameters:
      ;  dpl       dpl, disembodied property list of the tool
      ; 
      ;Return:
      ; sOutDir    string, path to output directory
      ;
      (putpropq 
        dpl->model
        (lambda (dpl)
          (let 
            ( ;local parameters
              sStartPhrase
              sEndPhrase
              sBoundingBox
              lShapes
              (port nil)
              tikzFileName
              (i 0)
              (shapeCount 0)
              (filesToCompile nil)
              (filesPerLayer nil)
              (filesForToplevel nil)
              (numOfChar 0)
              (maxNumOfCharPerLine 72)
              str
            )

            ;oFlattenCellView
            (putpropq 
              dpl->model
              (dbOpenCellViewByType 
                dpl->model->cv~>libName
                dpl->model->cv~>cellName
                (strcat 
                  dpl->model->cv~>viewName 
                  "_flatten_"
                  dpl->temp->sStartTime
                );strcat
                "maskLayout" 
                "w"
              );dbOpenCellViewByType
              oFlattenCellView
            );putpropq

            ;oCombinedCellView
            (putpropq
              dpl->model
              (dbOpenCellViewByType 
                dpl->model->cv~>libName
                dpl->model->cv~>cellName
                (strcat 
                  dpl->model->cv~>viewName 
                  "_combined_" 
                  dpl->temp->sStartTime
                );strcat
                "maskLayout" 
                "w"
              );dbOpenCellViewByType
              oCombinedCellView
            );putpropq

            (leFlattenInst 
              (dbCreateInst 
                dpl->model->oFlattenCellView
                dpl->model->cv
                "I0" 
                0:0 
                "R0"
              );dbCreateInst
              /* x_levels */               dpl->model->xLevels
              /* g_flattenPCells */        t
              /* g_preservePins */         nil
              /* g_preserveRODobjs */      nil
              /* g_delDetachedBlockages */ nil
              /* g_preservePinFigs */      t
              /* g_flattenVias */          t
            );leFlattenInst

            (foreach lLayer dpl->model->lLayers
              (dbLayerOr
                dpl->model->oCombinedCellView
                lLayer
                (setof 
                  x 
                  dpl->model->oFlattenCellView~>shapes 
                  (and
                    (equal x~>lpp lLayer)
                    (nequal x~>objType "ellipse")
                  );and
                );setof
              );dbLayerOr
            );foreach

            (foreach lLayer dpl->model->lLayers
              (foreach 
                ellipse 
                (setof 
                  x 
                  dpl->model->oFlattenCellView~>shapes 
                  (and
                    (equal x~>lpp lLayer)
                    (equal x~>objType "ellipse")
                  );and
                );setof 

                (dbCopyShape ellipse dpl->model->oCombinedCellView)
              );foreach
            );foreach

            dpl->model->xNumOfShapes = 0

            (foreach lLayer dpl->model->lLayers
              (putpropq
                dpl->model
                (plus
                  dpl->model->xNumOfShapes
                  (length
                    (setof 
                      x 
                      dpl->model->oFlattenCellView~>shapes 
                      (equal x~>lpp lLayer)
                    );setof
                  );length
                );plus
                xNumOfShapes
              );putpropq
            );foreach

            (when 
              (and 
                (greaterp
                  dpl->model->xNumOfShapes
                  dpl->model->xShapesPerFile
                );greaterp
                (not dpl->model->bSplitLayers)
              );and

              (putpropq 
                dpl->model
                (ceiling
                  (quotient 
                    dpl->model->xNumOfShapes
                    (ceiling 
                      (times
                        1.0
                        (quotient 
                          dpl->model->xNumOfShapes
                          dpl->model->xShapesPerFile
                        );quotient
                      );times
                    );ceiling
                  );quotient
                );ceiling
                xShapesPerFile
              );putpropq
            );when

            (dbSave dpl->model->oFlattenCellView)
            (dbSave dpl->model->oCombinedCellView)

            (createDir dpl->model->sOutDir)

            (shell
              (strcat 
                "cp "
                dpl->model->sLayersLatexFile 
                " "
                dpl->model->sOutDir 
                dpl->model->sLayersLatexFileName
              );strcat
            );shell

            (setq
              sStartPhrase
              (strcat
                "\\documentclass{standalone}\n"
                "\\usepackage{tikz}\n"
                "\\usepackage{graphicx}\n"
                "\\input{" dpl->model->sLayersLatexFileName "}\n"
                "\\begin{document}\n"
                "\\begin{tikzpicture}[x=" 
                (lsprintf "%L" dpl->model->nGridSize)
                "cm,y="
                (lsprintf "%L" dpl->model->nGridSize)
                "cm]\n"
              );strcat
            );setq

            (setq
              sBoundingBox
              (lsprintf
                "\\useasboundingbox (%L,%L) rectangle (%L,%L);\n"
                (if dpl->model->bBox 
                  (xCoord (lowerLeft dpl->model->bBox))
                  (difference
                    (xCoord (lowerLeft dpl->model->oCombinedCellView~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );difference
                );if
                (if dpl->model->bBox 
                  (yCoord (lowerLeft dpl->model->bBox))
                  (difference
                    (yCoord (lowerLeft dpl->model->oCombinedCellView~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );difference
                );if
                (if dpl->model->bBox
                  (xCoord (upperRight dpl->model->bBox))
                  (plus
                    (xCoord (upperRight dpl->model->oCombinedCellView~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );plus
                );if
                (if dpl->model->bBox
                  (yCoord (upperRight dpl->model->bBox))
                  (plus
                    (yCoord (upperRight dpl->model->oCombinedCellView~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );plus
                );if
              );lsprintf
            );setq

            (setq sEndPhrase "\\end{tikzpicture}\n\\end{document}")

            (foreach lLayer dpl->model->lLayers

              (setq 
                lShapes 
                (setof 
                  x 
                  dpl->model->oCombinedCellView~>shapes 
                  (equal x~>lpp lLayer)
                );setof
              );setq

              (if dpl->model->bSplitLayers then

                (if 
                  (geqp
                    dpl->model->xShapesPerFile 
                    (length lShapes)  
                  );geqp
                then

                  (setq
                    tikzFileName 
                    (lsprintf "%s|%s" (car lLayer) (cadr lLayer))
                  );setq

                  (setq i -1)
                  (setq 
                    filesForToplevel 
                    (cons tikzFileName filesForToplevel)
                  );setq
                else

                  (setq
                    tikzFileName
                    (lsprintf "%s_%s_0" (car lLayer) (cadr lLayer))
                  );setq
                  (setq i 0)
                  (setq
                    filesPerLayer
                    (cons tikzFileName filesPerLayer)
                  );setq
                );if

                (setq
                  port
                  (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                );setq

                (fprintf port "%s%s" sStartPhrase sBoundingBox)
              else
                (unless (portp port)

                  (if 
                    (leqp
                      dpl->model->xNumOfShapes
                      dpl->model->xShapesPerFile
                    );leqp
                  then

                    (setq 
                      tikzFileName 
                      (lsprintf 
                        "%s_%s_%s" 
                        dpl->model->cv~>libName
                        dpl->model->cv~>cellName
                        dpl->model->cv~>viewName
                      );lsprintf
                    );setq
                    
                  else

                    (setq tikzFileName "0")  
                    (setq 
                      filesForToplevel 
                      (cons tikzFileName filesForToplevel)
                    );setq
                  );if

                  (setq filesToCompile (cons tikzFileName filesToCompile))
                  (setq
                    port 
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq  
                  (fprintf port "%s%s" sStartPhrase sBoundingBox)

                );unless
              );if

              (foreach shape lShapes

                (when (equal shape~>objType "rect")

                  (fprintf 
                    port
                    "\\draw[%s|%s] (%L,%L) rectangle (%L,%L);\n" 
                    (car lLayer)
                    (cadr lLayer)
                    (xCoord (lowerLeft shape~>bBox))
                    (yCoord (lowerLeft shape~>bBox))  
                    (xCoord (upperRight shape~>bBox))
                    (yCoord (upperRight shape~>bBox))
                  );fprintf
                );when

                (when (equal shape~>objType "polygon")

                  (setq
                    str
                    (lsprintf
                      "\\draw[%s|%s] (%L,%L)"
                      (car lLayer) 
                      (cadr lLayer)
                      (xCoord (car shape~>points)) 
                      (yCoord (car shape~>points))
                    );lsprintf
                  );setq

                  (setq numOfChar (strlen str))

                  (fprintf port str)

                  (foreach lPoint (cdr shape~>points)

                    (setq
                      str
                      (lsprintf
                        " -- (%L,%L)"
                        (xCoord lPoint)
                        (yCoord lPoint)
                      );lsprintf
                    );setq

                    (setq numOfChar (plus numOfChar (strlen str)))

                    (when (greaterp numOfChar maxNumOfCharPerLine)
                      (fprintf port  "\n\t")
                      (setq numOfChar (plus 2 (strlen str)))
                    );when

                    (fprintf port  str)
                  );foreach

                  (fprintf port " -- cycle;\n")
                );when

                (when (equal shape~>objType "ellipse")

                  (fprintf 
                    port
                    "\\draw[%s|%s] (%L,%L) circle [x radius=%L, y radius=%L];\n" 
                    (car lLayer)
                    (cadr lLayer)

                    (xCoord (centerBox shape~>bBox))
                    (yCoord (centerBox shape~>bBox))

                    (quotient 
                      (difference 
                        (rightEdge shape~>bBox)
                        (leftEdge shape~>bBox)
                      );difference
                      2.0
                    );quotient

                    (quotient 
                      (difference 
                        (topEdge shape~>bBox)
                        (bottomEdge shape~>bBox)
                      );difference
                      2.0
                    );quotient
                  );fprintf
                );when

                (preincrement shapeCount)

                (when (geqp shapeCount dpl->model->xShapesPerFile)

                  (fprintf port "%s" sEndPhrase)
                  (close port)

                  (if dpl->model->bSplitLayers then
                    (setq 
                      tikzFileName 
                      (lsprintf 
                        "%s_%s_%L" 
                        (car lLayer) 
                        (cadr lLayer) 
                        (preincrement i)
                      );lsprintf
                    );setq
                    (setq filesPerLayer (cons tikzFileName filesPerLayer))
                  else

                    (setq tikzFileName (lsprintf "%L" (preincrement i)))
                    (setq
                      filesForToplevel
                      (cons tikzFileName filesForToplevel)
                    );setq
                    (setq filesToCompile (cons tikzFileName filesToCompile))
                  );if

                  (setq
                    port 
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq
                  (fprintf port "%s%s" sStartPhrase sBoundingBox)
                  (setq shapeCount 0)
                );when
              );foreach
              
              (when dpl->model->bSplitLayers

                (fprintf port "%s" sEndPhrase)
                (close port)

                (when (geqp i 0)
      
                  (setq
                    tikzFileName 
                    (lsprintf "layout_%s_%s" (car lLayer) (cadr lLayer))
                  );setq

                  (setq
                    port
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq

                  (fprintf port "%s" sStartPhrase)

                  (setq
                    filesToCompile
                    (cons 
                      (append
                        (list tikzFileName)
                        (reverse filesPerLayer)
                      );append
                      filesToCompile
                    );cons
                  );setq

                  (foreach fileName (reverse filesPerLayer)
                    (fprintf
                      port 
                      "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                      fileName
                    );fprintf
                  );foreach

                  (fprintf port "%s" sEndPhrase)
                  (close port)

                  (setq
                    filesForToplevel
                    (cons tikzFileName filesForToplevel)
                  );setq

                  (setq filesPerLayer nil)
                  (setq i 0)  
                  (setq shapeCount 0)
                );when
              );when    
            );foreach

            (unless dpl->model->bSplitLayers
              (fprintf port "%s" sEndPhrase)
              (close port)
            );unless

            (when filesForToplevel

              (setq 
                tikzFileName 
                (lsprintf 
                  "%s_%s_%s" 
                  dpl->model->cv~>libName  
                  dpl->model->cv~>cellName 
                  dpl->model->cv~>viewName
                );lsprintf
              );setq

              (setq 
                port 
                (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
              );setq

              (fprintf port "%s" sStartPhrase)

              (setq filesToCompile (cons tikzFileName filesToCompile))

              (foreach sFileName (reverse filesForToplevel)
                (fprintf
                  port 
                  "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                  sFileName
                );fprintf
              );foreach

              (fprintf port "%s" sEndPhrase)
              (close port)             
            );when
            
            (setq port (outfile (strcat dpl->model->sOutDir "Makefile")))
            (fprintf port "LATEXCOMPILER=%s\n" dpl->model->sLatexCompiler)
            (fprintf port "\n")

            (fprintf port "\nall:")

            (foreach file (reverse (cdr filesToCompile))
              (if (listp file)
                (fprintf port " %s.pdf" (car file))
                (fprintf port " %s.pdf" file)
              );if
            );foreach

            (fprintf port "\n\t${LATEXCOMPILER} %s.tex\n" (car filesToCompile))

            (foreach file (reverse (cdr filesToCompile))

              (if (listp file) then

                (fprintf port "\n%s.pdf:" (car file))

                (foreach item (cdr file)
                  (fprintf port " %s.pdf" item)    
                );foreach

                (fprintf port "\n\t${LATEXCOMPILER} %s.tex" (car file))
                (fprintf port "\n")

                (foreach item (cdr file)
                  (fprintf port "\n%s.pdf:" item)
                  (fprintf port "\n\t${LATEXCOMPILER} %s.tex" item)
                  (fprintf port "\n")
                );foreach

              else
                (fprintf port "\n%s.pdf:" file)
                (fprintf port "\n\t${LATEXCOMPILER} %s.tex" file)
                (fprintf port "\n")
              );if
            );foreach

            (close port)
            
            (when dpl->model->bMake 
              (shell (strcat "cd " dpl->model->sOutDir "\n" "make"))
            );when

            (let (dFlattenCellView dCombinedCellView)

              (setq
                dFlattenCellView
                (ddGetObj
                  dpl->model->oFlattenCellView~>libName
                  dpl->model->oFlattenCellView~>cellName
                  dpl->model->oFlattenCellView~>viewName
                );ddGetObj
              );setq

              (setq
                dCombinedCellView
                (ddGetObj
                  dpl->model->oCombinedCellView~>libName
                  dpl->model->oCombinedCellView~>cellName
                  dpl->model->oCombinedCellView~>viewName
                );ddGetObj
              );setq

              (dbClose dpl->model->oFlattenCellView)
              (dbClose dpl->model->oCombinedCellView)

              (unless dpl->model->bDebug
                (ddDeleteObj dFlattenCellView)
                (ddDeleteObj dCombinedCellView)
              );unless
            );let
          
            dpl->model->sOutDir
          );let
        );lambda
        fWriteTikZ
      );putpropq


      ;LAMBDA FUNCTION
      ; fWriteTikZwithABE
      ;
      ;Description:
      ; Export the layout as TikZ using ABE
      ;
      ;Parameters:
      ;  dpl       dpl, disembodied property list of the tool
      ; 
      ;Return:
      ; sOutDir    string, path to output directory
      ;
      (putpropq 
        dpl->model
        (lambda (dpl)
          (let 
            ( ;local parameters
              sStartPhrase
              sEndPhrase
              sBoundingBox
              (port nil)
              tikzFileName
              (i 0)
              (shapeCount 0)
              (filesToCompile nil)
              (filesPerLayer nil)
              (filesForToplevel nil)
              (numOfChar 0)
              (maxNumOfCharPerLine 72)
              str
              tileIter
              abeLayers
              shape
            )

            (abeInit 
              dpl->model->cv
              ?doInterrupts t
              ?threads dpl->model->xParallelABEruns
            );abeInit

            (setq
              abeLayers
              (foreach mapcar layer dpl->model->lLayers
                (list
                  layer
                  (abeLayerMergeTiles
                    (abeLayerFromCellView
                      (car layer)
                      ?purpose (cadr layer)
                      ?startLevel 0
                      ?stopLevel dpl->model->xLevels
                    );abeLayerFromCellView
                    "horizontal"
                    ?queue t
                  );abeLayerMergeTiles
                );list
              );foreach
            );setq

            (abeRunQueue)

            ;count all shapes
            (putpropq
              dpl->model
              (apply
                (quote plus)
                (foreach mapcar abeLayer abeLayers
                  (getq (cadr abeLayer) numTiles)
                );foreach
              );apply
              xNumOfShapes
            );putpropq

            ;calculate shapes per file
            (when 
              (and 
                (greaterp
                  dpl->model->xNumOfShapes
                  dpl->model->xShapesPerFile
                );greaterp
                (not dpl->model->bSplitLayers)
              );and

              (putpropq 
                dpl->model
                (ceiling
                  (quotient 
                    dpl->model->xNumOfShapes
                    (ceiling 
                      (times
                        1.0
                        (quotient 
                          dpl->model->xNumOfShapes
                          dpl->model->xShapesPerFile
                        );quotient
                      );times
                    );ceiling
                  );quotient
                );ceiling
                xShapesPerFile
              );putpropq
            );when

            (createDir dpl->model->sOutDir)

            (shell
              (strcat 
                "cp "
                dpl->model->sLayersLatexFile 
                " "
                dpl->model->sOutDir 
                dpl->model->sLayersLatexFileName
              );strcat
            );shell

            (setq
              sStartPhrase
              (strcat
                "\\documentclass{standalone}\n"
                "\\usepackage{tikz}\n"
                "\\usepackage{graphicx}\n"
                "\\input{" dpl->model->sLayersLatexFileName "}\n"
                "\\begin{document}\n"
                "\\begin{tikzpicture}[x=" 
                (lsprintf "%L" dpl->model->nGridSize)
                "cm,y="
                (lsprintf "%L" dpl->model->nGridSize)
                "cm]\n"
              );strcat
            );setq

            (setq
              sBoundingBox
              (lsprintf
                "\\useasboundingbox (%L,%L) rectangle (%L,%L);\n"
                (if dpl->model->bBox 
                  (xCoord (lowerLeft dpl->model->bBox))
                  (difference
                    (xCoord (lowerLeft dpl->model->cv~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );difference
                );if
                (if dpl->model->bBox 
                  (yCoord (lowerLeft dpl->model->bBox))
                  (difference
                    (yCoord (lowerLeft dpl->model->cv~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );difference
                );if
                (if dpl->model->bBox
                  (xCoord (upperRight dpl->model->bBox))
                  (plus
                    (xCoord (upperRight dpl->model->cv~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );plus
                );if
                (if dpl->model->bBox
                  (yCoord (upperRight dpl->model->bBox))
                  (plus
                    (yCoord (upperRight dpl->model->cv~>bBox))
                    (plus dpl->model->nMargin 0.01)
                  );plus
                );if
              );lsprintf
            );setq

            (setq
              sEndPhrase
              "\\end{tikzpicture}\n\\end{document}"
            );setq

            (foreach abeLayer abeLayers

              (setq tileIter (abeIslandIterator (cadr abeLayer)))

              (if dpl->model->bSplitLayers then

                (if 
                  (geqp
                    dpl->model->xShapesPerFile
                    (getq (cadr abeLayer) numTiles)
                  );geqp
                then

                  (setq
                    tikzFileName 
                    (lsprintf "%s_%s" (caar abeLayer) (cadar abeLayer))
                  );setq

                  (setq i -1)

                  (setq 
                    filesForToplevel 
                    (cons tikzFileName filesForToplevel)
                  );setq
                else

                  (setq
                    tikzFileName
                    (lsprintf "%s_%s_0" (caar abeLayer) (cadar abeLayer))
                  );setq

                  (setq i 0)

                  (setq
                    filesPerLayer
                    (cons tikzFileName filesPerLayer)
                  );setq
                );if

                (setq
                  port
                  (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                );setq

                (fprintf port "%s%s" sStartPhrase sBoundingBox)
              else
                
                (unless (portp port)

                  (if 
                    (leqp
                      dpl->model->xNumOfShapes
                      dpl->model->xShapesPerFile
                    );leqp
                  then

                    (setq 
                      tikzFileName 
                      (lsprintf 
                        "%s_%s_%s" 
                        dpl->model->cv~>libName
                        dpl->model->cv~>cellName
                        dpl->model->cv~>viewName
                      );lsprintf
                    );setq
                    
                  else

                    (setq tikzFileName "0")  

                    (setq 
                      filesForToplevel 
                      (cons tikzFileName filesForToplevel)
                    );setq
                  );if

                  (setq filesToCompile (cons tikzFileName filesToCompile))
                  (setq
                    port 
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq  
                  (fprintf port "%s%s" sStartPhrase sBoundingBox)
                );unless
              );if

              (while (setq shape tileIter->next)

                (setq
                  str
                  (lsprintf
                    "\\draw[%s|%s] (%L,%L)"
                    (caar abeLayer) 
                    (cadar abeLayer)
                    (xCoord (car shape))
                    (yCoord (cadr shape))
                  );lsprintf
                );setq

                (setq numOfChar (strlen str))

                (fprintf port str)

                (foreach point (cdr shape)

                  (setq
                    str
                    (lsprintf
                      " -- (%L,%L)"
                      (xCoord point)
                      (yCoord point)
                    );lsprintf
                  );setq

                  (setq numOfChar (plus numOfChar (strlen str)))

                  (when (greaterp numOfChar maxNumOfCharPerLine)
                    (fprintf port  "\n\t")
                    (setq numOfChar (plus 2 (strlen str)))
                  );when

                  (fprintf port  str)
                );foreach

                (fprintf port " -- cycle;\n")

                (preincrement shapeCount)

                (when (geqp shapeCount dpl->model->xShapesPerFile)

                  (fprintf port "%s" sEndPhrase)
                  (close port)

                  (if dpl->model->bSplitLayers then
                    (setq 
                      tikzFileName 
                      (lsprintf 
                        "%s_%s_%L" 
                        (caar abeLayer) 
                        (cadar abeLayer) 
                        (preincrement i)
                      );lsprintf
                    );setq

                    (setq filesPerLayer (cons tikzFileName filesPerLayer))
                  else

                    (setq tikzFileName (lsprintf "%L" (preincrement i)))
                    (setq
                      filesForToplevel
                      (cons tikzFileName filesForToplevel)
                    );setq
                    (setq filesToCompile (cons tikzFileName filesToCompile))
                  );if

                  (setq
                    port 
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq

                  (fprintf port "%s%s" sStartPhrase sBoundingBox)
                  
                  (setq shapeCount 0)
                );when
              );while
              
              (when dpl->model->bSplitLayers

                (fprintf port "%s" sEndPhrase)
                (close port)

                (when (geqp i 0)
      
                  (setq
                    tikzFileName 
                    (lsprintf "layout_%s_%s" (caar abeLayer) (cadar abeLayer))
                  );setq

                  (setq
                    port
                    (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
                  );setq

                  (fprintf port "%s" sStartPhrase)

                  (setq
                    filesToCompile
                    (cons 
                      (append
                        (list tikzFileName)
                        (reverse filesPerLayer)
                      );append
                      filesToCompile
                    );cons
                  );setq

                  (foreach fileName (reverse filesPerLayer)
                    (fprintf
                      port 
                      "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                      fileName
                    );fprintf
                  );foreach

                  (fprintf port "%s" sEndPhrase)
                  (close port)

                  (setq
                    filesForToplevel
                    (cons tikzFileName filesForToplevel)
                  );setq

                  (setq filesPerLayer nil)
                  (setq i 0)  
                  (setq shapeCount 0)
                );when
              );when    
            );foreach

            (unless dpl->model->bSplitLayers
              (fprintf port "%s" sEndPhrase)
              (close port)
            );unless

            (when filesForToplevel

              (setq 
                tikzFileName 
                (lsprintf 
                  "%s_%s_%s" 
                  dpl->model->cv~>libName  
                  dpl->model->cv~>cellName 
                  dpl->model->cv~>viewName
                );lsprintf
              );setq

              (setq 
                port 
                (outfile (strcat dpl->model->sOutDir tikzFileName ".tex"))
              );setq

              (fprintf port "%s" sStartPhrase)

              (setq filesToCompile (cons tikzFileName filesToCompile))

              (foreach fileName (reverse filesForToplevel)
                (fprintf
                  port 
                  "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                  fileName
                );fprintf
              );foreach

              (fprintf port "%s" sEndPhrase)
              (close port)             
            );when
            
            (setq port (outfile (strcat dpl->model->sOutDir "Makefile")))
            (fprintf port "LATEXCOMPILER=%s\n" dpl->model->sLatexCompiler)
            (fprintf port "\n")

            (fprintf port "\nall:")

            (foreach file (reverse (cdr filesToCompile))
              (if (listp file)
                (fprintf port " %s.pdf" (car file))
                (fprintf port " %s.pdf" file)
              );if
            );foreach

            (fprintf port "\n\t${LATEXCOMPILER} %s.tex\n" (car filesToCompile))

            (foreach file (reverse (cdr filesToCompile))

              (if (listp file) then

                (fprintf port "\n%s.pdf:" (car file))

                (foreach item (cdr file)
                  (fprintf port " %s.pdf" item)    
                );foreach

                (fprintf port "\n\t${LATEXCOMPILER} %s.tex" (car file))
                (fprintf port "\n")

                (foreach item (cdr file)
                  (fprintf port "\n%s.pdf:" item)
                  (fprintf port "\n\t${LATEXCOMPILER} %s.tex" item)
                  (fprintf port "\n")
                );foreach

              else
                (fprintf port "\n%s.pdf:" file)
                (fprintf port "\n\t${LATEXCOMPILER} %s.tex" file)
                (fprintf port "\n")
              );if
            );foreach

            (close port)
            
            (when dpl->model->bMake 
              (shell (strcat "cd " dpl->model->sOutDir "\n" "make"))
            );when

            (abeDone)

            dpl->model->sOutDir
          );let
        );lambda
        fWriteTikZwithABE
      );putpropq


      ;LAMBDA FUNCTION
      ; fCheckInout
      ;
      ;Description:
      ; Check if the input data that is provided to the tool is valid
      ;
      ;Parameters:
      ;  dpl       dpl, disembodied property list of the tool
      ; 
      ;Return:
      ; t/nil      bool, 't' when data valid, 'nil' otherwise
      ;
      (putpropq 
        dpl->model
        (lambda (dpl)
          (and
            (if dpl->model->fReadInLayersLatexFile(dpl) then
              t
            else
              (fprintf
                errport
                "*[ED] ml2TikZ* No valid layers in %L\n"
                dpl->model->sLayersLatexFile
              );fprintf
              nil
            );if
            (if 
              (or 
                (and
                  (isDir dpl->model->sOutDir)
                  (isWritable dpl->model->sOutDir)
                );and
                (and
                  (createDir dpl->model->sOutDir)
                  (deleteDir dpl->model->sOutDir)
                );and
              );or
            then

              (putpropq 
                dpl->model
                (strcat 
                  "/" 
                  (buildString
                    (parseString (simplifyFilename dpl->model->sOutDir) "/") 
                    "/"
                  );buildString
                  "/"
                );strcat
                sOutDir
              );putpropq

            else
              (fprintf
                errport
                "*[ED] ml2TikZ* No valid output directory is specified\n"
              );fprintf
              nil
            );if

            (if 
              (and 
                (fixp dpl->model->xShapesPerFile)
                (greaterp dpl->model->xShapesPerFile 0)
              );and 
            then
              t
            else
              dpl->model->xShapesPerFile = 1000
            );if

            (if (stringp dpl->model->sLatexCompiler) then
              t
            else
              (fprintf errport "*[ED] ml2TikZ* No LaTeX compiler specified\n")
              nil
            );if

            (if 
              (and 
                (numberp dpl->model->nGridSize) 
                (greaterp dpl->model->nGridSize 0)
              );and
            then
              t
            else
              (fprintf errport "*[ED] ml2TikZ* No valid grid size specified\n")
              nil
            );if
          );and
        );lambda
        fCheckInout
      );putpropq
    );unless

    (when bGraphicalMode
      
      (unless dpl->view

        dpl->view = (list nil)
        dpl->view->forms = (list nil)
        dpl->view->callbacks = (list nil)

        ; 'maskLayout 2 TikZ' form 
        ;
        ;  +---------------------------------------+-+-+
        ;  | [ED] maskLayout 2 TikZ                |v|x|
        ;  +---------------------------------------+-+-+
        ;  |                                           |          v
        ;  |                      +----------+  +---+  |          |
        ;  | Output Directory     |          |  |...|  | <- 1.1   |
        ;  |                      +----------+  +---+  |          |
        ;  |                                           |          |
        ;  |                      +----------+  +---+  |          |
        ;  | Layers Latex File    |          |  |...|  | <- 1.2   |  
        ;  |                      +----------+  +---+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | # Levels             |                 |  | <- 1.3   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | Grid Size [cm]       |                 |  | <- 1.4   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | Margin               |                 |  | <- 1.5   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | Latex Compiler       |                 |  | <- 1.6   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |1
        ;  |                      +---+                |          |
        ;  | Use ABE              | v |                | <- 1.7   |
        ;  |                      +---+                |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | # Parallel ABE runs  |                 |  | <- 1.8   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | # Shapes per File    |                 |  | <- 1.9   |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +-----------------+  |          |
        ;  | Open with            |                 |  | <- 1.10  |
        ;  |                      +-----------------+  |          |
        ;  |                                           |          |
        ;  |                      +---+                |          |
        ;  | Split Layers         | v |                | <- 1.11  |
        ;  |                      +---+                |          |
        ;  |                                           |          |
        ;  |                      +---+                |          |
        ;  | Make                 |   |                | <- 1.12  |
        ;  |                      +---+                |          |
        ;  |                                           |          |
        ;  |                      +---+                |          |
        ;  | Debug                |   |                | <- 1.13  |
        ;  |                      +---+                |          ^
        ;  |                                           |
        ;  |  +----+  +--------+  +-------+  +------+  |
        ;  |  | OK |  | Cancel |  | Apply |  | Help |  |
        ;  |  +----+  +--------+  +-------+  +------+  |
        ;  +-------------------------------------------+


        ;outDirFileSelectorField (1.1)
        (putpropq 
          dpl->view->forms
          (hiCreateFileSelectorField
            ?name (quote outDirFileSelectorField)
            ?mode (quote directoryOnly)
            ?prompt "Output Directory"
            ?value ""
          );hiCreateFileSelectorField
          outDirFileSelectorField
        );putpropq

        ;latexFileFileSelectorField (1.2)
        (putpropq 
          dpl->view->forms
          (hiCreateFileSelectorField
            ?name (quote latexFileFileSelectorField)
            ?mode (quote existingFile)
            ?prompt "Layers Latex File"
            ?value
              (if dpl->model->sLayersLatexFile then
                dpl->model->sLayersLatexFile
              else
                (let ((envvar "ED_ML2TIKZ_LAYERS") path)

                  (setq path (getShellEnvVar envvar))
                  
                  (if 
                    (and
                      (stringp path)
                      (isFile path)
                      (isReadable path)
                    );and
                    path
                    " "
                  );if
                );let
              );if
          );hiCreateFileSelectorField
          latexFileFileSelectorField
        );putpropq

        ;levelsIntField (1.3)
        (putpropq 
          dpl->view->forms
          (hiCreateIntField
            ?name (quote levelsIntField)
            ?prompt "# Levels"
            ?value 
              (if (fixp dpl->model->xLevels)
                dpl->model->xLevels
                32
              );if
            ?range (list 0 32)
          );hiCreateIntField
          levelsIntField
        );putpropq

        ;gridSizeFloatForm (1.4)
        (putpropq 
          dpl->view->forms
          (hiCreateFloatField
            ?name (quote gridSizeFloatForm)
            ?prompt "Grid Size [cm]"
            ?value 
              (if (numberp dpl->model->nGridSize) 
                dpl->model->nGridSize 
                1.0
              );if
            ?range (list 0.0001 nil)
          );hiCreateFloatField
          gridSizeFloatForm
        );putpropq
        
        ;marginFloatForm (1.5)
        (putpropq 
          dpl->view->forms
          (hiCreateFloatField
            ?name (quote marginFloatForm)
            ?prompt "Margin"
            ?value 
              (if (numberp dpl->model->nMargin)
                dpl->model->nMargin
                0.0
              );if
            ?range (list 0.0 nil)
          );hiCreateFloatField
          marginFloatForm
        );putpropq

        ;latexCompilerStringField (1.6)
        (putpropq 
          dpl->view->forms
          (hiCreateStringField
            ?name (quote latexCompilerStringField)
            ?prompt "Latex Compiler"
            ?value 
              (if (stringp dpl->model->sLatexCompiler)
                dpl->model->sLatexCompiler 
                "pdflatex"
              );if
          );hiCreateStringField
          latexCompilerStringField
        );putpropq

        ;abeBooleanButton (1.7)
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote abeBooleanButton)
            ?buttonText "Use ABE"
            ?defValue dpl->model->bAbe
          );hiCreateBooleanButton
          abeBooleanButton
        );putpropq

        ;parallelABEruns (1.8)
        (putpropq 
          dpl->view->forms
          (hiCreateIntField
            ?name (quote parallelABEruns)
            ?prompt "# Parallel ABE runs"
            ?editable nil
            ?value 
              1
              ;(if (fixp dpl->model->xParallelABEruns)
              ;  dpl->model->xParallelABEruns
              ;  1
              ;);if
            ?range (list 1 "infinity")
          );hiCreateIntField
          parallelABEruns
        );putpropq

        ;shapesPerFileIntField (1.9)
        (putpropq 
          dpl->view->forms
          (hiCreateIntField
            ?name (quote shapesPerFileIntField)
            ?prompt "# Shapes per File"
            ?value 
              (if (fixp dpl->model->xShapesPerFile)
                dpl->model->xShapesPerFile
                1000
              );if
            ?range (list 1 "infinity")
          );hiCreateIntField
          shapesPerFileIntField
        );putpropq
        
        ;openWithStringField (1.10)
        (putpropq 
          dpl->view->forms
          (hiCreateStringField
            ?name  (quote openWithStringField)
            ?prompt "Open with"
            ?value 
              (if (stringp dpl->model->sOpenWith) 
                dpl->model->sOpenWith 
                ""
              );if
          );hiCreateStringField
          openWithStringField
        );putpropq

        ;splitLayerBooleanButton (1.11)
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote splitLayerBooleanButton)
            ?buttonText "Split Layers"
            ?value dpl->model->bSplitLayers
          );hiCreateBooleanButton
          splitLayerBooleanButton
        );putpropq

        ;makeBooleanButton (1.12)
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote makeBooleanButton)
            ?buttonText "Make"
            ?defValue dpl->model->bMake
          );hiCreateBooleanButton
          makeBooleanButton
        );putpropq

        ;debugBooleanButton (1.13)
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote debugBooleanButton)
            ?buttonText "Debug"
            ?defValue dpl->model->bDebug
          );hiCreateBooleanButton
          debugBooleanButton
        );putpropq

        ;EDml2TikZFormLayout (1)
        (putpropq 
          dpl->view->forms
          (hiCreateFormLayout
            (quote EDml2TikZFormLayout)
            ?frame "EDml2TikZFormLayout"
            ?items
              (foreach mapcar form dpl->view->forms->?
                (get dpl->view->forms form)
              );foreach
          );hiCreateFormLayout
          EDml2TikZFormLayout
        );putpropq

        ;EDml2TikZLayoutForm
        (putpropq
          dpl->view->forms
          (hiCreateLayoutForm
            (quote EDml2TikZLayoutForm)
            "[ED] maskLayout 2 TikZ"
            dpl->view->forms->EDml2TikZFormLayout
            ?sizePolicy (quote fixed)
            ?dialogStyle (quote modal)
            ?buttonLayout (quote OKCancelApply)
            ?callback
              (list
                (strcat 
                  "EDml2TikZ.dpl->view->callbacks"
                  "->fExecuteMl2TikZ(EDml2TikZ.dpl)"
                );strcat
                "nil"
              );list
          );hiCreateLayoutForm
          EDml2TikZLayoutForm
        );putpropq

        (putpropq
          (quote EDml2TikZLayoutForm)
          "(hiLaunchBrowser \"https://github.com/electronics-and-drives/ml2tikz\")"
          hiHelpAction
        );putpropq
        
        ;fExecuteMl2TikZ
        (putpropq
          dpl->view->callbacks
          (lambda (dpl)

            (putpropq 
              dpl->model
              (simplifyFilename
                dpl->view->forms->latexFileFileSelectorField->value
              );simplifyFilename
              sLayersLatexFile
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->outDirFileSelectorField->value
              sOutDir
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->levelsIntField->value
              xLevels
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->parallelABEruns->value
              xParallelABEruns
            );putpropq            

            (putpropq 
              dpl->model
              dpl->view->forms->shapesPerFileIntField->value
              xShapesPerFile
            );putpropq
            
            (putpropq 
              dpl->model
              dpl->view->forms->latexCompilerStringField->value
              sLatexCompiler
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->abeBooleanButton->value
              bAbe
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->makeBooleanButton->value
              bMake
            );putpropq
            
            (putpropq 
              dpl->model
              dpl->view->forms->debugBooleanButton->value
              bDebug
            );putpropq

            (putpropq 
              dpl->model
              dpl->view->forms->gridSizeFloatForm->value
              nGridSize
            );putpropq
            
            (putpropq 
              dpl->model
              dpl->view->forms->splitLayerBooleanButton->value
              bSplitLayers
            );putpropq 

            (putpropq 
              dpl->model
              dpl->view->forms->marginFloatForm->value
              nMargin
            );putpropq             

            (if 
              (and 
                dpl->view->forms->openWithStringField->value 
                (greaterp 
                  (strlen dpl->view->forms->openWithStringField->value) 
                  0
                );greaterp
              );and
            then
              (putpropq 
                dpl->model
                dpl->view->forms->openWithStringField->value
                sOpenWith 
              );putpropq
            else
              dpl->model->sOpenWith = nil
            );if

            (when dpl->model->fCheckInout(dpl)

              (if dpl->model->bAbe then
                dpl->model->fWriteTikZwithABE(dpl) 
              else
                dpl->model->fWriteTikZ(dpl) 
              );if

              
              (if dpl->model->sOpenWith
                (system 
                  (strcat 
                    dpl->model->sOpenWith
                    " " 
                    dpl->model->sOutDir
                  );strcat
                );system
                (hiDisplayAppDBox 
                  ?name (quote rEDml2TikZres) 
                  ?dboxBanner "[ED] maskLayout 2 TikZ Result" 
                  ?dboxText dpl->model->sOutDir
                  ?dialogType 3 
                  ?buttonLayout (quote Close)
                );hiDisplayAppDBox
              );if
            );when
          );lambda
          fExecuteMl2TikZ
        );putpropq
      );unless
    );when

    dpl->temp = (list nil)

    ;get and format current time
    (putpropq 
      dpl->temp
      (buildString (parseString (getCurrentTime) ": ") "_")
      sStartTime 
    );putpropq

    (if   
      (and
        oCellView
        (dbIsId oCellView)
        (equal "maskLayout" oCellView~>cellViewType)
      );and
    then

      dpl->model->cv = oCellView

      (if bGraphicalMode then

        (putpropq
          dpl->view->forms->EDml2TikZLayoutForm->outDirFileSelectorField
          (lsprintf
            "./%s_%s_%s"
            dpl->model->cv~>libName
            dpl->model->cv~>cellName
            dpl->model->cv~>viewName
          );lsprintf
          value
        );putpropq

        (hiDisplayForm dpl->view->forms->EDml2TikZLayoutForm)
      else

        dpl->model->sLayersLatexFile = sLayersLatexFile
        dpl->model->cv = oCellView
        dpl->model->sOutDir = sOutDir
        dpl->model->bAbe = bAbe
        dpl->model->xParallelABEruns = 1
        dpl->model->xLevels = xLevels
        ;dpl->model->xParallelABEruns = xParallelABEruns
        dpl->model->xShapesPerFile = xShapesPerFile
        dpl->model->sLatexCompiler =sLatexCompiler
        dpl->model->bMake = bMake
        dpl->model->bDebug = bDebug
        dpl->model->nGridSize = nGridSize
        dpl->model->bSplitLayers = bSplitLayers
        dpl->model->nMargin = nMargin
        dpl->model->bBox = bBox

        (when dpl->model->fCheckInout(dpl)

          (if dpl->model->bAbe then
            dpl->model->fWriteTikZwithABE(dpl) 
          else
            dpl->model->fWriteTikZ(dpl) 
          );if
        );when
      );if
    else
      (fprintf errport "*[ED] ml2TikZ* No valid maskLayout view found\n")
    );if
  );let
);defun EDml2TikZ