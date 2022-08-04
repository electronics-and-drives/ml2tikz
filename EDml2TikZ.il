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
*         {sklint ?file "PATH" ?globals '(ML2TIKZ ML2TIKZLayoutPulldownMenu)}
*
*   Revision:   2019-03-29 Created
*               2019-04-16 Added GUI
*               2019-06-05 Added margin
*               2019-12-24 refractured/output dir by user/bBox
*
*   Copyright 2019 Reutlingen University (Germany)
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
(defun 
  ML2TIKZ
  (
    @key
    (oCellView (geGetWindowCellView))
    (sOutDir "./")
    (sLayersLatexFile nil)
    (sLatexCompiler "pdflatex")   
    (nGridSize 1.0)
    (bDebug nil)
    (xShapesPerFile 1000)
    (bSplitLayers nil)
    (bBox nil)
    (bMake t)
    (nMargin 0)
    (bGraphicalMode nil)
  )

  (let (v)

    (setq v 'ML2TIKZ)

    (unless (boundp 'ML2TIKZ)
      (set 'ML2TIKZ (list nil))
    );unless

    (setq v (eval v))
    v->temp = (list nil)
    v->model = (list nil)

    (putpropq 
      v->temp
      (buildString (parseString (getCurrentTime) ": ") "_")
      sStartTime 
    );putpropq

    ;fReadInLayersLatexFile
    (putpropq 
      v->model
      (lambda (v)
        (let (s pPort)

          v->model->lLayers = nil

          (when 
            (and
              (stringp v->model->sLayersLatexFile)
              (isFile v->model->sLayersLatexFile)
              (isReadable v->model->sLayersLatexFile)
            );and

            v->model->sLayersLatexFileName = (car (last (parseString v->model->sLayersLatexFile "/")))

            (setq pPort (infile v->model->sLayersLatexFile))

            (while (gets s pPort)

              (rexCompile "[ ]*\\tikzstyle{[ ]*\\([a-zA-Z_0-9]*\\)[ ]*}.*")

              (when (rexExecute s) && (equal (length (parseString (rexSubstitute "\\1") "_")) 2)
                  (putpropq 
                      v->model
                    (cons
                      (parseString (rexSubstitute "\\1") "_")
                      v->model->lLayers
                    );cons
                    lLayers
                  );putpropq
              );when
            );while

            (putpropq 
                v->model
              (reverse v->model->lLayers)
              lLayers
            );putpropq  
          );when
          v->model->lLayers    
        );let
      );lambda
      fReadInLayersLatexFile
    );putpropq

    ;fWriteTikZ
    (putpropq 
      v->model
      (lambda (v)
        (let 
          ( ;local parameters
            sStartPhrase
            sEndPhrase
            sBoundingBox
            lShapes
            (pTikZ nil)
            pMakefile
            sTikZFileName
            (i 0)
            (xShapeCount 0)
            (lFilesToCompile nil)
            (lFilesPerLayer nil)
            (lFilesForToplevel nil)
            (numOfChar 0)
            (maxNumOfCharPerLine 72)
            str
          )

          ;oFlattenCellView
          (putpropq 
            v->model
            (dbOpenCellViewByType 
              v->model->oSourceCellView~>libName
              v->model->oSourceCellView~>cellName
              (strcat 
                v->model->oSourceCellView~>viewName 
                "_flatten_" 
                v->temp->sStartTime
              );strcat
              "maskLayout" 
              "w"
            );dbOpenCellViewByType
            oFlattenCellView
          );putpropq

          ;oCombinedCellView
          (putpropq
            v->model
            (dbOpenCellViewByType 
              v->model->oSourceCellView~>libName
              v->model->oSourceCellView~>cellName
              (strcat 
                v->model->oSourceCellView~>viewName 
                "_combined_" 
                v->temp->sStartTime
              );strcat
              "maskLayout" 
              "w"
            );dbOpenCellViewByType
            oCombinedCellView
          );putpropq

          (leFlattenInst 
            (dbCreateInst 
              v->model->oFlattenCellView
              v->model->oSourceCellView
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

          v->model->xNumOfShapes = 0

          (foreach lLayer v->model->lLayers
            (putpropq
              v->model
              (plus
                v->model->xNumOfShapes
                (length
                  (dbLayerOr
                    v->model->oCombinedCellView
                    lLayer
                    (setof 
                      x 
                      v->model->oFlattenCellView~>shapes 
                      (equal x~>lpp lLayer)
                    );setof
                  );dbLayerOr
                );length
              );plus
              xNumOfShapes
            );putpropq
          );foreach

          (when 
            (and 
              (greaterp
                v->model->xNumOfShapes
                v->model->xShapesPerFile
              );greaterp
              (not v->model->bSplitLayers)
            );and

            (putpropq 
              v->model
              (ceiling
                (quotient 
                  v->model->xNumOfShapes
                  (ceiling 
                    (times
                      1.0
                      (quotient 
                        v->model->xNumOfShapes
                        v->model->xShapesPerFile
                      );quotient
                    );times
                  );ceiling
                );quotient
              );ceiling
              xShapesPerFile
            );putpropq
          );when

          (dbSave v->model->oFlattenCellView)
          (dbSave v->model->oCombinedCellView)

          (createDir v->model->sOutDir)

          (shell
            (strcat 
              "cp "
              v->model->sLayersLatexFile 
              " "
              v->model->sOutDir 
              v->model->sLayersLatexFileName
            );strcat
          );shell

          (setq
            sStartPhrase
            (strcat
              "\\documentclass{standalone}\n"
              "\\usepackage{tikz}\n"
              "\\usepackage{graphicx}\n"
              "\\input{" v->model->sLayersLatexFileName "}\n"
              "\\begin{document}\n"
              "\\begin{tikzpicture}[x=" 
              (lsprintf "%L" v->model->nGridSize)
              "cm,y="
              (lsprintf "%L" v->model->nGridSize)
              "cm]\n"
            );strcat
          );setq

          (setq
            sBoundingBox
            (lsprintf
              (strcat
                "\\draw[line width = 0mm,white,opacity=1.0]"
                " (%L,%L) rectangle (%L,%L);\n"
              );strcat
              (if v->model->bBox 
                (xCoord (lowerLeft v->model->bBox))
                (difference
                  (xCoord (lowerLeft v->model->oCombinedCellView~>bBox))
                  (plus v->model->nMargin 0.01)
                );difference
              );if
              (if v->model->bBox 
                (yCoord (lowerLeft v->model->bBox))
                (difference
                  (yCoord (lowerLeft v->model->oCombinedCellView~>bBox))
                  (plus v->model->nMargin 0.01)
                );difference
              );if
              (if v->model->bBox
                (xCoord (upperRight v->model->bBox))
                (plus
                  (xCoord (upperRight v->model->oCombinedCellView~>bBox))
                  (plus v->model->nMargin 0.01)
                );plus
              );if
              (if v->model->bBox
                (yCoord (upperRight v->model->bBox))
                (plus
                  (yCoord (upperRight v->model->oCombinedCellView~>bBox))
                  (plus v->model->nMargin 0.01)
                );plus
              );if
            );lsprintf
          );setq

          (setq sEndPhrase "\\end{tikzpicture}\n\\end{document}")

          (foreach lLayer v->model->lLayers

            (setq 
              lShapes 
              (setof 
                x 
                v->model->oCombinedCellView~>shapes 
                x~>lpp==lLayer
              );setof
            );setq

            (if v->model->bSplitLayers then

              (if v->model->xShapesPerFile >= (length lShapes)  then

                (setq
                  sTikZFileName 
                  (lsprintf "%s_%s" (car lLayer) (cadr lLayer))
                );setq

                (setq i -1)
                (setq 
                  lFilesForToplevel 
                  (cons sTikZFileName lFilesForToplevel)
                );setq
              else

                (setq
                  sTikZFileName
                  (lsprintf "%s_%s_0" (car lLayer) (cadr lLayer))
                );setq
                (setq i 0)
                (setq
                  lFilesPerLayer
                  (cons sTikZFileName lFilesPerLayer)
                );setq
              );if

              (setq
                pTikZ
                (outfile (strcat v->model->sOutDir sTikZFileName ".tex"))
              );setq

              (fprintf pTikZ "%s%s" sStartPhrase sBoundingBox)
              (setq lFilesToCompile (cons sTikZFileName lFilesToCompile))
            else
              (unless (portp pTikZ)

                (if v->model->xNumOfShapes <= v->model->xShapesPerFile  then

                  (setq 
                    sTikZFileName 
                    (lsprintf 
                      "%s_%s_%s" 
                      v->model->oSourceCellView~>libName
                      v->model->oSourceCellView~>cellName
                      v->model->oSourceCellView~>viewName
                    );lsprintf
                  );setq
                  
                else

                  (setq sTikZFileName "0")  
                  (setq 
                    lFilesForToplevel 
                    (cons sTikZFileName lFilesForToplevel)
                  );setq
                );if

                (setq lFilesToCompile (cons sTikZFileName lFilesToCompile))
                (setq
                  pTikZ 
                  (outfile (strcat v->model->sOutDir sTikZFileName ".tex"))
                );setq  
                (fprintf pTikZ "%s%s" sStartPhrase sBoundingBox)

              );unless
            );if

            (foreach oShape lShapes

              (if (equal oShape~>objType "rect") then

                (fprintf 
                  pTikZ
                  "\\draw[%s_%s] (%L,%L) rectangle (%L,%L);\n" 
                  (car lLayer)
                  (cadr lLayer)
                  (xCoord (lowerLeft oShape~>bBox))
                  (yCoord (lowerLeft oShape~>bBox))  
                  (xCoord (upperRight oShape~>bBox))
                  (yCoord (upperRight oShape~>bBox))
                );fprintf

              else

                (when (equal oShape~>objType "polygon")

                  (setq
                    str
                    (lsprintf
                      "\\draw[%s_%s] (%L,%L)"
                      (car lLayer) 
                      (cadr lLayer)
                      (xCoord (car oShape~>points)) 
                      (yCoord (car oShape~>points))
                    );lsprintf
                  );setq

                  (setq numOfChar (strlen str))

                  (fprintf pTikZ str)

                  (foreach lPoint (cdr oShape~>points)

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
                      (fprintf pTikZ  "\n\t")
                      (setq numOfChar (plus 2 (strlen str)))
                    );when

                    (fprintf pTikZ  str)
                  );foreach

                  (fprintf pTikZ " -- cycle;\n")

                );when
              );if

              (preincrement xShapeCount)

              (when xShapeCount >= v->model->xShapesPerFile

                (fprintf pTikZ "%s" sEndPhrase)
                (close pTikZ)

                (if v->model->bSplitLayers then
                  (setq 
                    sTikZFileName 
                    (lsprintf 
                      "%s_%s_%L" 
                      (car lLayer) 
                      (cadr lLayer) 
                      (preincrement i)
                    );lsprintf
                  );setq
                  (setq lFilesPerLayer (cons sTikZFileName lFilesPerLayer))
                else

                  (setq sTikZFileName (lsprintf "%L" (preincrement i)))
                  (setq
                    lFilesForToplevel
                    (cons sTikZFileName lFilesForToplevel)
                  );setq
                );if

                (setq
                  pTikZ 
                  (outfile (strcat v->model->sOutDir sTikZFileName ".tex"))
                );setq
                (fprintf pTikZ "%s%s" sStartPhrase sBoundingBox)
                (setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

                (setq xShapeCount 0)
              );when
            );foreach
            
            (when v->model->bSplitLayers

              (fprintf pTikZ "%s" sEndPhrase)
              (close pTikZ)

              (when (geqp i 0)
    
                (setq
                  sTikZFileName 
                  (lsprintf "layout_%s_%s" (car lLayer) (cadr lLayer))
                );setq

                (setq
                  pTikZ
                  (outfile (strcat v->model->sOutDir sTikZFileName ".tex"))
                );setq

                (fprintf pTikZ "%s" sStartPhrase)

                (setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

                (foreach sFileName (reverse lFilesPerLayer)
                  (fprintf
                    pTikZ 
                    "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                    sFileName
                  );fprintf
                );foreach

                (fprintf pTikZ "%s" sEndPhrase)
                (close pTikZ)

                (setq lFilesForToplevel (cons sTikZFileName lFilesForToplevel))

                (setq lFilesPerLayer nil)
                (setq i 0)  
                (setq xShapeCount 0)
              );when
            );when    
          );foreach

          (unless v->model->bSplitLayers
            (fprintf pTikZ "%s" sEndPhrase)
            (close pTikZ)
          );unless

          (when lFilesForToplevel

            (setq 
              sTikZFileName 
              (lsprintf 
                "%s_%s_%s" 
                v->model->oSourceCellView~>libName  
                v->model->oSourceCellView~>cellName 
                v->model->oSourceCellView~>viewName
              );lsprintf
            );setq

            (setq 
              pTikZ 
              (outfile (strcat v->model->sOutDir sTikZFileName ".tex"))
            );setq

            (fprintf pTikZ "%s" sStartPhrase)

            (setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

            (foreach sFileName (reverse lFilesForToplevel)
              (fprintf
                pTikZ 
                "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" 
                sFileName
              );fprintf
            );foreach

            (fprintf pTikZ "%s" sEndPhrase)
            (close pTikZ)             
          );when
          
          (setq pMakefile (outfile (strcat v->model->sOutDir "Makefile")))
          (fprintf pMakefile "LATEXCOMPILER=%s\n" v->model->sLatexCompiler)
          (fprintf pMakefile "\n")

          (fprintf pMakefile "\nall:")

          (foreach sFileName (reverse (cdr lFilesToCompile))
            (fprintf pMakefile " %s.pdf" sFileName)
          );foreach

          (fprintf pMakefile "\n\t${LATEXCOMPILER} %s.tex\n" (car lFilesToCompile))

          (foreach sFileName (reverse (cdr lFilesToCompile))
            (fprintf pMakefile "\n%s.pdf:" sFileName)
            (fprintf pMakefile "\n\t${LATEXCOMPILER} %s.tex" sFileName)
            (fprintf pMakefile "\n")
          );foreach

          (close pMakefile)
          
          (when v->model->bMake 
            (shell (strcat "cd " v->model->sOutDir "\n" "make"))
          );when

          (let (dFlattenCellView dCombinedCellView)

            (setq
              dFlattenCellView
              (ddGetObj
                v->model->oFlattenCellView~>libName
                v->model->oFlattenCellView~>cellName
                v->model->oFlattenCellView~>viewName
              );ddGetObj
            );setq

            (setq
              dCombinedCellView
              (ddGetObj
                v->model->oCombinedCellView~>libName
                v->model->oCombinedCellView~>cellName
                v->model->oCombinedCellView~>viewName
              );ddGetObj
            );setq

            (dbClose v->model->oFlattenCellView)
            (dbClose v->model->oCombinedCellView)

            (unless v->model->bDebug
              (ddDeleteObj dFlattenCellView)
              (ddDeleteObj dCombinedCellView)
            );unless
          );let
        
          v->model->sOutDir
        );let
      );lambda
      fWriteTikZ
    );putpropq

    ;fCheckInout
    (putpropq 
      v->model
      (lambda (v)
        (and
          (if v->model->fReadInLayersLatexFile(v) then
            t
          else
            (fprintf
              errport
              "*mL2TikZ* No valid layers in %L\n"
              v->model->sLayersLatexFile
            );fprintf
            nil
          );if
          (if 
            (or 
              (and
                (isDir v->model->sOutDir)
                (isWritable v->model->sOutDir)
              );and
              (and
                (createDir v->model->sOutDir)
                (deleteDir v->model->sOutDir)
              );and
            );or
          then

            (putpropq 
              v->model
              (strcat 
                "/" 
                (buildString
                  (parseString (simplifyFilename v->model->sOutDir) "/") 
                  "/"
                );buildString
                "/"
              );strcat
              sOutDir
            );putpropq

          else
            (fprintf
              errport
              "*mL2TikZ* No valid output directory is specified\n"
            );fprintf
            nil
          );if

          (if 
            (and 
              (fixp v->model->xShapesPerFile)
              (greaterp v->model->xShapesPerFile 0)
            );and 
          then
            t
          else
            v->model->xShapesPerFile = 1000
          );if

          (if (stringp v->model->sLatexCompiler) then
            t
          else
            (fprintf errport "*mL2TikZ* No LaTeX compiler specified\n")
            nil
          );if

          (if 
            (and 
              (numberp v->model->nGridSize) 
              (greaterp v->model->nGridSize 0)
            );and

          then
              t
          else
            (fprintf errport "*mL2TikZ* No valid grid size specified\n")
            nil
          );if
        );and
      );lambda
      fCheckInout
    );putpropq

    (if   
      (and
        oCellView
        (dbIsId oCellView)
        (equal "maskLayout" oCellView~>cellViewType)
      );and
      
      then

      v->model->oSourceCellView = oCellView

      (if bGraphicalMode then

        v->view = (list nil)
        v->view->forms = (list nil)
        v->view->callbacks = (list nil)

        ;rOutDirFileSelectorField
        (putpropq 
          v->view->forms
          (hiCreateFileSelectorField
            ?name 'rOutDirFileSelectorField
            ?mode 'directoryOnly
            ?prompt "Output Dir"
            ?value
                    (lsprintf
                      "./%s_%s_%s"
                      v->model->oSourceCellView~>libName
                      v->model->oSourceCellView~>cellName
                      v->model->oSourceCellView~>viewName
                    );lsprintf
          );hiCreateFileSelectorField
          rOutDirFileSelectorField
        );putpropq

        ;rLatexFileFileSelectorField
        (putpropq 
          v->view->forms
          (hiCreateFileSelectorField
            ?name 'rLatexFileFileSelectorField
            ?mode 'existingFile
            ?prompt "Layers Latex File"
            ?value
              (if v->model->sLayersLatexFile then
                v->model->sLayersLatexFile
              else
                " "
              );if
          );hiCreateFileSelectorField
          rLatexFileFileSelectorField
        );putpropq

        ;rGridSizeFloatForm
        (putpropq 
          v->view->forms
          (hiCreateFloatField
            ?name 'rGridSizeFloatForm
            ?prompt "Grid Size [cm]"
            ?value 
              (if (numberp v->model->nGridSize) 
                v->model->nGridSize 
                1.0
              );if
            ?range (list 0.0001 nil)
          );hiCreateFloatField
          rGridSizeFloatForm
        );putpropq
        
        ;rMarginFloatForm
        (putpropq 
          v->view->forms
          (hiCreateFloatField
            ?name 'rMarginFloatForm
            ?prompt "Margin"
            ?value 
              (if (numberp v->model->nMargin)
                v->model->nMargin
                0.0
              );if
            ?range (list 0.0 nil)
          );hiCreateFloatField
          rMarginFloatForm
        );putpropq

        ;rLatexCompilerStringField
        (putpropq 
          v->view->forms
          (hiCreateStringField
            ?name 'rLatexCompilerStringField
            ?prompt "Latex Compiler"
            ?value 
              (if (stringp v->model->sLatexCompiler)
                v->model->sLatexCompiler 
                "pdflatex"
              );if
          );hiCreateStringField
          rLatexCompilerStringField
        );putpropq

        ;rShapesPerFileIntField
        (putpropq 
          v->view->forms
          (hiCreateIntField
            ?name 'rShapesPerFileIntField
            ?prompt "# Shapes per File"
            ?value 
              (if (fixp v->model->xShapesPerFile)
                v->model->xShapesPerFile
                1000
              );if
            ?range (list 1 "infinity")
          );hiCreateIntField
          rShapesPerFileIntField
        );putpropq
        
        ;rOpenWithStringField
        (putpropq 
          v->view->forms
          (hiCreateStringField
            ?name 'rOpenWithStringField
            ?prompt "Open with"
            ?value 
              (if (stringp v->model->sOpenWith) 
                v->model->sOpenWith 
                ""
              );if
          );hiCreateStringField
          rOpenWithStringField
        );putpropq

        ;rSplitLayerBooleanButton
        (putpropq 
          v->view->forms
          (hiCreateBooleanButton
            ?name 'rSplitLayerBooleanButton
            ?buttonText "Split Layers"
            ?value v->model->bSplitLayers
          );hiCreateBooleanButton
          rSplitLayerBooleanButton
        );putpropq

        ;rMakeBooleanButton
        (putpropq 
          v->view->forms
          (hiCreateBooleanButton
            ?name 'rMakeBooleanButton
            ?buttonText "Make"
            ?defValue v->model->bMake
          );hiCreateBooleanButton
          rMakeBooleanButton
        );putpropq

        ;rDebugBooleanButton
        (putpropq 
          v->view->forms
          (hiCreateBooleanButton
            ?name 'rDebugBooleanButton
            ?buttonText "Debug"
            ?defValue v->model->bDebug
          );hiCreateBooleanButton
          rDebugBooleanButton
        );putpropq

        ;rML2TIKZFormLayout
        (putpropq 
          v->view->forms
          (hiCreateFormLayout
            'rML2TIKZFormLayout
            ?frame "rML2TIKZFormLayout"
            ?items
              (foreach mapcar sForm v->view->forms->?
                (get v->view->forms sForm)
              );foreach
          );hiCreateFormLayout
          rML2TIKZFormLayout
        );putpropq

        ;rML2TIKZLayoutForm
        (putpropq
          v->view->forms
          (hiCreateLayoutForm
            'rML2TIKZLayoutForm
            "ML2TikZ"
            v->view->forms->rML2TIKZFormLayout
            ?sizePolicy 'fixed
            ?dialogStyle 'modal
            ?buttonLayout 'OKCancelApply
            ?callback
              (list
                (strcat 
                  "(eval 'ML2TIKZ)->view->callbacks"
                  "->fExecuteML2TIKZ((eval 'ML2TIKZ))"
                );strcat
                "nil"
              );list
            ?buttonDisabled (list 'Help)
          );hiCreateLayoutForm
          rML2TIKZLayoutForm
        );putpropq
        
        ;fExecuteML2TIKZ
        (putpropq
          v->view->callbacks
          (lambda (v)

            (putpropq 
              v->model
              (simplifyFilename v->view->forms->rLatexFileFileSelectorField->value)
              sLayersLatexFile
            );putpropq

            (putpropq 
              v->model
              v->view->forms->rOutDirFileSelectorField->value
              sOutDir
            );putpropq

            (putpropq 
              v->model
              v->view->forms->rShapesPerFileIntField->value
              xShapesPerFile
            );putpropq
            
            (putpropq 
              v->model
              v->view->forms->rLatexCompilerStringField->value
              sLatexCompiler
            );putpropq

            (putpropq 
              v->model
              v->view->forms->rMakeBooleanButton->value
              bMake
            );putpropq
            
            (putpropq 
              v->model
              v->view->forms->rDebugBooleanButton->value
              bDebug
            );putpropq

            (putpropq 
              v->model
              v->view->forms->rGridSizeFloatForm->value
              nGridSize
            );putpropq
            
            (putpropq 
              v->model
              v->view->forms->rSplitLayerBooleanButton->value
              bSplitLayers
            );putpropq 

            (putpropq 
              v->model
              v->view->forms->rMarginFloatForm->value
              nMargin
            );putpropq             

            (if 
              (and 
                v->view->forms->rOpenWithStringField->value 
                (greaterp 
                  (strlen v->view->forms->rOpenWithStringField->value) 
                  0
                );greaterp
              );and
            then
              (putpropq 
                v->model
                v->view->forms->rOpenWithStringField->value
                sOpenWith 
              );putpropq
            else
              v->model->sOpenWith = nil
            );if

            (when v->model->fCheckInout(v)
            
              v->model->fWriteTikZ(v)
              
              (if v->model->sOpenWith
                (system 
                  (strcat 
                    v->model->sOpenWith
                    " " 
                    v->model->sOutDir
                  );strcat
                );system
                (hiDisplayAppDBox 
                  ?name 'rML2TIKZres 
                  ?dboxBanner "ML2TikZ Result" 
                  ?dboxText v->model->sOutDir
                  ?dialogType 3 
                  ?buttonLayout 
                  'Close
                );hiDisplayAppDBox
              );if
            );when
          );lambda
          fExecuteML2TIKZ
        );putpropq

        (hiDisplayForm v->view->forms->rML2TIKZLayoutForm)
      else

        v->model->sLayersLatexFile = sLayersLatexFile
        v->model->oSourceCellView = oCellView
        v->model->sOutDir = sOutDir
        v->model->xShapesPerFile = xShapesPerFile
        v->model->sLatexCompiler =sLatexCompiler
        v->model->bMake = bMake
        v->model->bDebug = bDebug
        v->model->nGridSize = nGridSize
        v->model->bSplitLayers = bSplitLayers
        v->model->nMargin = nMargin
        v->model->bBox = bBox

        (when v->model->fCheckInout(v)
          v->model->fWriteTikZ(v)
        );when
      );if
    else
      (fprintf errport "*mL2TikZ* No valid maskLayout view found\n")
    );if
  );let
);defun

(defun ML2TIKZCreateLayoutPulldownMenu ()
  (if (boundp 'ML2TIKZLayoutPulldownMenu) then 
    ML2TIKZLayoutPulldownMenu
  else
    (hiCreatePulldownMenu
      'ML2TIKZLayoutPulldownMenu
      "Export"
      (list
        (hiCreateMenuItem
          ?name 'ML2TIKZMenuItem
          ?itemText "mL2TikZ"
          ?callback "(ML2TIKZ ?bGraphicalMode t)"
        );hiCreateMenuItem
      );list
    );hiCreatePulldownMenu
  );if
);defun

(defun ML2TIKZUserPostInstallTrigger (args)

  (let (pulldownMenu)

    (setq pulldownMenu (ML2TIKZCreateLayoutPulldownMenu))

    ;insert pulldown menu when not registered
    (unless
      (apply
        'or
        (foreach mapcar menu (hiGetBannerMenus args->window)
          (equal pulldownMenu (eval menu))
        );foreach
      );apply

      (hiInsertBannerMenu
        args->window
        pulldownMenu
        (length (hiGetBannerMenus args->window))
      );hiInsertBannerMenu
    );unless
  );let  
);procedure

(deRegUserTriggers "maskLayout" nil nil 'ML2TIKZUserPostInstallTrigger)
(deRegUserTriggers "maskLayoutXL" nil nil 'ML2TIKZUserPostInstallTrigger)