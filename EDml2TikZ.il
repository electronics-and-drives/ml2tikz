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
*   Globals:
*    - Symbols:
*     o EDml2TikZ
*     o Forms and Fields:
*      x EDml2TikZLayoutForm
*    - Functions:
*     o EDml2TikZ
*     o EDml2TikZCreateLayoutPulldownMenu
*     o EDml2TikZUserPostInstallTrigger
*
*   Revision:   2019-03-29 Created
*               2019-04-16 Added GUI
*               2019-06-05 Added margin
*               2019-12-24 refractured/output dir by user/bBox
*               2022-08-06 Use advanced boolean engine
*
*   Copyright 2022 Reutlingen University, Electronics & Drives (Germany)
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

    (setq dpl EDml2TikZ.dpl)

    (unless dpl->model

      dpl->model = (list nil)

      ;fReadInLayersLatexFile
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

              dpl->model->sLayersLatexFileName = (car (last (parseString dpl->model->sLayersLatexFile "/")))

              (setq pPort (infile dpl->model->sLayersLatexFile))

              (while (gets s pPort)

                (rexCompile "[ ]*\\tikzstyle{[ ]*\\([a-zA-Z_0-9]*\\)[ ]*}.*")

                (when (rexExecute s) && (equal (length (parseString (rexSubstitute "\\1") "_")) 2)
                    (putpropq 
                        dpl->model
                      (cons
                        (parseString (rexSubstitute "\\1") "_")
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

      ;fWriteTikZ
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
              /* x_levels */               32
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
                    (lsprintf "%s_%s" (car lLayer) (cadr lLayer))
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
                    "\\draw[%s_%s] (%L,%L) rectangle (%L,%L);\n" 
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
                      "\\draw[%s_%s] (%L,%L)"
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
                    "\\draw[%s_%s] (%L,%L) circle [x radius=%L, y radius=%L];\n" 
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

      ;fWriteTikZwithABE
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
                    (abeLayerFromCellView (car layer) ?purpose (cadr layer))
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
                    "\\draw[%s_%s] (%L,%L)"
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

      ;fCheckInout
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

        ;outDirFileSelectorField
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

        ;latexFileFileSelectorField
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
                " "
              );if
          );hiCreateFileSelectorField
          latexFileFileSelectorField
        );putpropq

        ;gridSizeFloatForm
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
        
        ;marginFloatForm
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

        ;latexCompilerStringField
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

        ;abeBooleanButton
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote abeBooleanButton)
            ?buttonText "Use ABE"
            ?defValue dpl->model->bAbe
          );hiCreateBooleanButton
          abeBooleanButton
        );putpropq

        ;parallelABEruns
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

        ;shapesPerFileIntField
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
        
        ;openWithStringField
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

        ;splitLayerBooleanButton
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote splitLayerBooleanButton)
            ?buttonText "Split Layers"
            ?value dpl->model->bSplitLayers
          );hiCreateBooleanButton
          splitLayerBooleanButton
        );putpropq

        ;makeBooleanButton
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote makeBooleanButton)
            ?buttonText "Make"
            ?defValue dpl->model->bMake
          );hiCreateBooleanButton
          makeBooleanButton
        );putpropq

        ;debugBooleanButton
        (putpropq 
          dpl->view->forms
          (hiCreateBooleanButton
            ?name (quote debugBooleanButton)
            ?buttonText "Debug"
            ?defValue dpl->model->bDebug
          );hiCreateBooleanButton
          debugBooleanButton
        );putpropq

        ;EDml2TikZFormLayout
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
            ?buttonDisabled (list (quote Help))
          );hiCreateLayoutForm
          EDml2TikZLayoutForm
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

;FUNCTION
; EDml2TikZCreateLayoutPulldownMenu
;
;Description:
; This function creates a pulldown menu
;
;Return:
; pulldown menu
;
(defun EDml2TikZCreateLayoutPulldownMenu ()
  (hiCreatePulldownMenu
    (quote EDml2TikZLayoutPulldownMenu)
    "Export"
    (list
      (hiCreateMenuItem
        ?name (quote EDml2TikZMenuItem)
        ?itemText "maskLayout 2 TikZ"
        ?callback "(EDml2TikZ ?bGraphicalMode t)"
      );hiCreateMenuItem
    );list
  );hiCreatePulldownMenu
);defun


;FUNCTION
; EDml2TikZUserPostInstallTrigger
;
;Description:
; This function is a trigger which added the tools menu item to the VLE
;
;Return:
; t             bool, always 't'
;
(defun EDml2TikZUserPostInstallTrigger (args)
  (when 
    (not
      (rexMatchList
        "EDml2TikZLayoutPulldownMenu"
        (hiGetBannerMenus args->window)
      );rexMatchList
    );not

    (hiInsertBannerMenu
      args->window 
      (if (boundp (quote EDml2TikZLayoutPulldownMenu))
        (eval (quote EDml2TikZLayoutPulldownMenu))
        (EDml2TikZCreateLayoutPulldownMenu)
      );if
      (length (hiGetBannerMenus args->window)) 
    );hiInsertBannerMenu
  );when
  t
);defun EDml2TikZUserPostInstallTrigger

;add trigger to Layout-L
(deRegUserTriggers
  "maskLayout"
  nil
  nil
  (quote EDml2TikZUserPostInstallTrigger)
);deRegUserTriggers

;add trigger to Layout-XL
(deRegUserTriggers
  "maskLayoutXL"
  nil
  nil
  (quote EDml2TikZUserPostInstallTrigger)
);deRegUserTriggers

;add trigger to Layout-GXL
(deRegUserTriggers
  "maskLayoutGXL"
  nil
  nil
  (quote EDml2TikZUserPostInstallTrigger)
);deRegUserTriggers