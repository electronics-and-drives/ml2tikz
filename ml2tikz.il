/*============================================================*
*
*   ml2tikz
*
*   Purpose:    maskLayout to tikzpicture converter
*
*   Author:     Matthias Schweikardt
*   Email:      matthias.schweikardt@reutlingen-university.de
*
*   Revision:   2019-03-29 Created
*               2019-04-16 Added GUI
*
*   Copyright 2019 Reutlingen University (Germany)
*
*   Permission is hereby granted, free of charge, to any person obtaining a copy of this software
*   and associated documentation files (the "Software"), to deal in the Software without restriction,
*   including without limitation the rights to use, copy, modify, merge, publish, distribute,
*   sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*
*   The above copyright notice and this permission notice shall be included in all copies or substantial
*   portions of the Software.
*
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
*   NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
*   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
*   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
*   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
*=============================================================*/

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
		(bMake t)
		(bGraphicalMode nil)
	)

	(let (v)

		(setq v	'ML2TIKZ)

		(unless (boundp v)
		    (set v (list nil))
		    (eval v)->temp = (list nil) 
		    (eval v)->model = (list nil)
		);unless
		
		(eval v)->temp->sStartTime = (buildString (parseString (getCurrentTime) ": ") "_")

		;fReadInLayersLatexFile
		(putpropq 
		    (eval v)->model
			(lambda (v)
				(let (s pPort)

					(eval v)->model->lLayers = nil

					(when 
						(and
							(stringp (eval v)->model->sLayersLatexFile)
							(isFile (eval v)->model->sLayersLatexFile)
							(isReadable (eval v)->model->sLayersLatexFile)
						);and

						(eval v)->model->sLayersLatexFileName = (car (last (parseString (eval v)->model->sLayersLatexFile "/")))

						(setq pPort (infile (eval v)->model->sLayersLatexFile))

						(while (gets s pPort)

						    (rexCompile "[ ]*\\tikzstyle{[ ]*\\([a-zA-Z_0-9]*\\)[ ]*}.*")

						    (when (rexExecute s) && (equal (length (parseString (rexSubstitute "\\1") "_")) 2)
						        (putpropq 
						            (eval v)->model
						        	(cons
						        		(parseString (rexSubstitute "\\1") "_")
						        		(eval v)->model->lLayers
						        	);cons
						        	lLayers
						        );putpropq
						    );when
						);while

						(putpropq 
						    (eval v)->model
							(reverse (eval v)->model->lLayers)
							lLayers
						);putpropq	
					);when
					(eval v)->model->lLayers    
				);let
			);lambda
			fReadInLayersLatexFile
		);putpropq

		;fWriteTikZ
		(putpropq 
		    (eval v)->model
			(lambda (v)
				(let 
					(	;local parameters
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
					)

					(putpropq 
						(eval v)->model
						(dbOpenCellViewByType 
							(eval v)->model->oSourceCellView~>libName
							(eval v)->model->oSourceCellView~>cellName
							(strcat 
								(eval v)->model->oSourceCellView~>viewName 
								"_flatten_" 
								(eval v)->temp->sStartTime
							);strcat
							"maskLayout" 
							"w"
						);dbOpenCellViewByType
						oFlattenCellView
					);putpropq

					(putpropq
						(eval v)->model
						(dbOpenCellViewByType 
							(eval v)->model->oSourceCellView~>libName
							(eval v)->model->oSourceCellView~>cellName
							(strcat 
								(eval v)->model->oSourceCellView~>viewName 
								"_combined_" 
								(eval v)->temp->sStartTime
							);strcat
							"maskLayout" 
							"w"
						);dbOpenCellViewByType
						oCombinedCellView
					);putpropq

					(leFlattenInst 
						(dbCreateInst 
							(eval v)->model->oFlattenCellView
							(eval v)->model->oSourceCellView
							"I0" 
							0:0 
							"R0"
						);dbCreateInst
						/* x_levels */ 				 32
						/* g_flattenPCells */ 		 t
						/* g_preservePins */ 		 nil
						/* g_preserveRODobjs */ 	 nil
						/* g_delDetachedBlockages */ nil
						/* g_preservePinFigs */ 	 nil
						/* g_flattenVias */ 		 t
					);leFlattenInst

					(eval v)->model->xNumOfShapes = 0

					(foreach lLayer (eval v)->model->lLayers
						(putpropq
						    (eval v)->model
							(plus
								(eval v)->model->xNumOfShapes
								(length
									(dbLayerOr
										(eval v)->model->oCombinedCellView
										(car lLayer)
										(setof x (eval v)->model->oFlattenCellView~>shapes (equal x~>lpp lLayer))
									);dbLayerOr
								);length
							);plus
							xNumOfShapes
						);putpropq
					);foreach

					(when (eval v)->model->xNumOfShapes > (eval v)->model->xShapesPerFile && (not (eval v)->model->bSplitLayers)

						(eval v)->model->xShapesPerFile = (ceiling (eval v)->model->xNumOfShapes/(ceiling 1.0*(eval v)->model->xNumOfShapes/(eval v)->model->xShapesPerFile))
					);when

					(dbSave (eval v)->model->oFlattenCellView)
					(dbSave (eval v)->model->oCombinedCellView)

					(putpropq 
					    (eval v)->model
						(strcat
							(eval v)->model->sOutDir
							(eval v)->model->oSourceCellView~>libName
							"_"
							(eval v)->model->oSourceCellView~>cellName
							"_"
							(eval v)->model->oSourceCellView~>viewName
							"_"
							(eval v)->temp->sStartTime
							"/"
						);strcat
						sOutDir
					);putpropq

					(createDir (eval v)->model->sOutDir)

					(shell (strcat "cp " (eval v)->model->sLayersLatexFile  " " (eval v)->model->sOutDir (eval v)->model->sLayersLatexFileName))

					(setq
						sStartPhrase
						(strcat
							"\\documentclass{standalone}\n"
							"\\usepackage{tikz}\n"
							"\\usepackage{graphicx}\n"
							"\\input{\"" (eval v)->model->sLayersLatexFileName "\"}\n"
							"\\begin{document}\n"
							"\\begin{tikzpicture}[x=" (lsprintf "%L" (eval v)->model->nGridSize) "cm,y=" (lsprintf "%L" (eval v)->model->nGridSize) "cm]\n"
						);strcat
					);setq

					(setq
						sBoundingBox
						(lsprintf
							"\\draw[line width = 0mm,white,opacity=1.0] (%L,%L) rectangle (%L,%L);\n"
							(xCoord (lowerLeft (eval v)->model->oCombinedCellView~>bBox))-0.01
							(yCoord (lowerLeft (eval v)->model->oCombinedCellView~>bBox))-0.01
							(xCoord (upperRight (eval v)->model->oCombinedCellView~>bBox))+0.01
							(yCoord (upperRight (eval v)->model->oCombinedCellView~>bBox))+0.01
						);lsprintf
					);setq

					(setq
						sEndPhrase
						(strcat
							"\\end{tikzpicture}\n"
							"\\end{document}"
						);strcat
					);setq

					(foreach lLayer (eval v)->model->lLayers

						(setq lShapes (setof x (eval v)->model->oCombinedCellView~>shapes x~>lpp==lLayer))

						(if (eval v)->model->bSplitLayers then

							(if (eval v)->model->xShapesPerFile >= (length lShapes)  then

								(setq sTikZFileName (lsprintf "%s_%s" (car lLayer) (cadr lLayer)))
								(setq i -1)
								(setq lFilesForToplevel (cons sTikZFileName lFilesForToplevel))
							else

								(setq sTikZFileName (lsprintf "%s_%s_0" (car lLayer) (cadr lLayer)))
								(setq i 0)
								(setq lFilesPerLayer (cons sTikZFileName lFilesPerLayer))
							);if

							(setq pTikZ (outfile (strcat (eval v)->model->sOutDir sTikZFileName ".tex")))			
							(fprintf pTikZ "%s%s" sStartPhrase sBoundingBox)
							(setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

						else
							(unless (portp pTikZ)

								(if (eval v)->model->xShapesPerFile >= (length lShapes)  then

									(setq 
										sTikZFileName 
										(lsprintf 
											"%s_%s_%s" 
											(eval v)->model->oSourceCellView~>libName
											(eval v)->model->oSourceCellView~>cellName
											(eval v)->model->oSourceCellView~>viewName
										);lsprintf
									);setq
								else

									(setq sTikZFileName "0")	
									(setq lFilesForToplevel (cons sTikZFileName lFilesForToplevel))
								);if

								(setq lFilesToCompile (cons sTikZFileName lFilesToCompile))
								(setq pTikZ (outfile (strcat (eval v)->model->sOutDir sTikZFileName ".tex")))			
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

									(fprintf 
										pTikZ 
										"\\draw[%s_%s] (%L,%L)" 
										(car lLayer) 
										(cadr lLayer)
										(xCoord (car oShape~>points)) 
										(yCoord (car oShape~>points))
									);fprintf

									(foreach lPoint (cdr oShape~>points)
										(fprintf pTikZ  " -- (%L,%L)" (xCoord lPoint) (yCoord lPoint))
									);foreach

									(fprintf pTikZ " -- cycle;\n")

								);when
							);if

							xShapeCount = xShapeCount + 1

							(when xShapeCount >= (eval v)->model->xShapesPerFile

								(fprintf pTikZ "%s" sEndPhrase)
								(close pTikZ)

								(if (eval v)->model->bSplitLayers then

									(setq sTikZFileName (lsprintf "%s_%s_%L" (car lLayer) (cadr lLayer) ++i))
									(setq lFilesPerLayer (cons sTikZFileName lFilesPerLayer))
								else
	
									(setq sTikZFileName (lsprintf "%L" ++i))
									(setq lFilesForToplevel (cons sTikZFileName lFilesForToplevel))

								);if

								(setq pTikZ (outfile (strcat (eval v)->model->sOutDir sTikZFileName ".tex")))	
								(fprintf pTikZ "%s%s" sStartPhrase sBoundingBox)
								(setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

								(setq xShapeCount 0)
							);when
						);foreach
						
						(when (eval v)->model->bSplitLayers

							(fprintf pTikZ "%s" sEndPhrase)
							(close pTikZ)

							(when i >= 0
		
								(setq sTikZFileName (lsprintf "layout_%s_%s" (car lLayer) (cadr lLayer)))
								(setq pTikZ (outfile (strcat (eval v)->model->sOutDir sTikZFileName ".tex")))			
								(fprintf pTikZ "%s" sStartPhrase)
								(setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

								(foreach sFileName (reverse lFilesPerLayer)
								    
									(fprintf pTikZ "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" sFileName)

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

					(unless (eval v)->model->bSplitLayers

						(fprintf pTikZ "%s" sEndPhrase)
						(close pTikZ)
					);unless

					(when lFilesForToplevel

						(setq sTikZFileName (lsprintf "%s_%s_%s" (eval v)->model->oSourceCellView~>libName  (eval v)->model->oSourceCellView~>cellName (eval v)->model->oSourceCellView~>viewName))
						(setq pTikZ (outfile (strcat (eval v)->model->sOutDir sTikZFileName ".tex")))
						(fprintf pTikZ "%s" sStartPhrase)

						(setq lFilesToCompile (cons sTikZFileName lFilesToCompile))

						(foreach sFileName (reverse lFilesForToplevel)

							(fprintf pTikZ "\\node at (0,0) {\\includegraphics{%s.pdf}};\n" sFileName)
						);foreach

						(fprintf pTikZ "%s" sEndPhrase)
						(close pTikZ)					    
					);when
					
					(setq pMakefile (outfile (strcat (eval v)->model->sOutDir "Makefile")))
					(fprintf pMakefile "LATEXCOMPILER=%s\n" (eval v)->model->sLatexCompiler)
					(fprintf pMakefile "\nmake:")

					(foreach sFileName (reverse lFilesToCompile)

						(fprintf pMakefile "\n\t${LATEXCOMPILER} %s.tex" sFileName)
					);foreach

					(close pMakefile)
					
					(when (eval v)->model->bMake 
						(shell (strcat "cd " (eval v)->model->sOutDir "\n" "make"))
					);when

					(let (dFlattenCellView dCombinedCellView)

						(setq
							dFlattenCellView
							(ddGetObj
								(eval v)->model->oFlattenCellView~>libName
								(eval v)->model->oFlattenCellView~>cellName
								(eval v)->model->oFlattenCellView~>viewName
							);ddGetObj
						);setq

						(setq
							dCombinedCellView
							(ddGetObj
								(eval v)->model->oCombinedCellView~>libName
								(eval v)->model->oCombinedCellView~>cellName
								(eval v)->model->oCombinedCellView~>viewName
							);ddGetObj
						);setq

						(dbClose (eval v)->model->oFlattenCellView)
						(dbClose (eval v)->model->oCombinedCellView)

						(unless (eval v)->model->bDebug

							(ddDeleteObj dFlattenCellView)
							(ddDeleteObj dCombinedCellView)
						);unless
					);let
				
					(eval v)->model->sOutDir
				);let
			);lambda
			fWriteTikZ
		);putpropq

		;fCheckInout
		(putpropq 
			(eval v)->model
			(lambda (v)
				(and
					(if (eval v)->model->fReadInLayersLatexFile(v) then
						t
					else
						(fprintf errport "*mL2TikZ* No valid layers in %L\n" (eval v)->model->sLayersLatexFile)
						nil
					);if
					(if (isDir (eval v)->model->sOutDir) && (isWritable (eval v)->model->sOutDir) then

						(eval v)->model->sOutDir = (strcat "/" (buildString (parseString (simplifyFilename (eval v)->model->sOutDir) "/") "/") "/")

					else
						(fprintf errport "*mL2TikZ* No valid output directory is specified\n")
						nil
					);if
					(if (fixp (eval v)->model->xShapesPerFile) && (eval v)->model->xShapesPerFile > 0 then
						t
					else
						(eval v)->model->xShapesPerFile = 1000
					);if
					(if (stringp (eval v)->model->sLatexCompiler) then
						t
					else
						(fprintf errport "*mL2TikZ* No LaTeX compiler specified\n")
						nil
					);if
					(if (numberp (eval v)->model->nGridSize) && (eval v)->model->nGridSize > 0 then
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

			(eval v)->model->oSourceCellView = oCellView

			(if bGraphicalMode then

				(eval v)->view = (list nil)
				(eval v)->view->forms = (list nil)
				(eval v)->view->callbacks = (list nil)

				;rOutDirFileSelectorField
				(putpropq 
					(eval v)->view->forms
					(hiCreateFileSelectorField
						?name 'rOutDirFileSelectorField
						?mode 'directoryOnly
						?prompt "Output Dir"
						?value
							(if (eval v)->model->sOutDir then
								(eval v)->model->sOutDir
							else
								" "
							);if
					);hiCreateFileSelectorField
					rOutDirFileSelectorField
				);putpropq

				;rLatexFileFileSelectorField
				(putpropq 
					(eval v)->view->forms
					(hiCreateFileSelectorField
						?name 'rLatexFileFileSelectorField
						?mode 'existingFile
						?prompt "Layers Latex File"
						?value
							(if (eval v)->model->sLayersLatexFile then
								(eval v)->model->sLayersLatexFile
							else
								" "
							);if
					);hiCreateFileSelectorField
					rLatexFileFileSelectorField
				);putpropq

				;rGridSizeFloatForm
				(putpropq 
					(eval v)->view->forms
					(hiCreateFloatField
						?name 'rGridSizeFloatForm
						?prompt "Grid Size [cm]"
						?value (if (numberp (eval v)->model->nGridSize) then (eval v)->model->nGridSize else 1.0)
						?range list(0.1 nil)
					);hiCreateFloatField
					rGridSizeFloatForm
				);putpropq

				;rLatexCompilerStringField
				(putpropq 
					(eval v)->view->forms
					(hiCreateStringField
						?name 'rLatexCompilerStringField
						?prompt "Latex Compiler"
						?value (if (stringp (eval v)->model->sLatexCompiler) then (eval v)->model->sLatexCompiler else "pdflatex")
					);hiCreateStringField
					rLatexCompilerStringField
				);putpropq

				;rShapesPerFileIntField
				(putpropq 
					(eval v)->view->forms
					(hiCreateIntField
						?name 'rShapesPerFileIntField
						?prompt "# Shapes per File"
						?value (if (fixp (eval v)->model->xShapesPerFile) then (eval v)->model->xShapesPerFile else 1000)
						?range (list 1 "infinity")
					);hiCreateIntField
					rShapesPerFileIntField
				);putpropq

				;rSplitLayerBooleanButton
				(putpropq 
					(eval v)->view->forms
					(hiCreateBooleanButton
						?name 'rSplitLayerBooleanButton
						?buttonText "Split Layers"
						?value (eval v)->model->bSplitLayers
					);hiCreateBooleanButton
					rSplitLayerBooleanButton
				);putpropq

				;rMakeBooleanButton
				(putpropq 
					(eval v)->view->forms
					(hiCreateBooleanButton
						?name 'rMakeBooleanButton
						?buttonText "Make"
						?defValue (eval v)->model->bMake
					);hiCreateBooleanButton
					rMakeBooleanButton
				);putpropq

				;rDebugBooleanButton
				(putpropq 
					(eval v)->view->forms
					(hiCreateBooleanButton
						?name 'rDebugBooleanButton
						?buttonText "Debug"
						?defValue (eval v)->model->bDebug
					);hiCreateBooleanButton
					rDebugBooleanButton
				);putpropq

				;rML2TIKZFormLayout
				(putpropq 
					(eval v)->view->forms
					(hiCreateFormLayout
						'rML2TIKZFormLayout
						?frame "rML2TIKZFormLayout"
						?items
							(foreach mapcar sForm (eval v)->view->forms->?
								(get (eval v)->view->forms sForm)
							);foreach
					);hiCreateFormLayout
					rML2TIKZFormLayout
				);putpropq

				;rML2TIKZLayoutForm
				(putpropq
					(eval v)->view->forms
					(hiCreateLayoutForm
						'rML2TIKZLayoutForm
						"ML2TikZ"
						(eval v)->view->forms->rML2TIKZFormLayout
						?sizePolicy 'fixed
						?dialogStyle 'modal
						?buttonLayout 'OKCancelApply
						?callback
							(list
								"(eval 'ML2TIKZ)->view->callbacks->fExecuteML2TIKZ('ML2TIKZ)"
								"nil"
							);list
					);hiCreateLayoutForm
					rML2TIKZLayoutForm
				);putpropq

				;fExecuteML2TIKZ
				(putpropq
					(eval v)->view->callbacks
					(lambda (v)

						(eval v)->model->sLayersLatexFile 	= (eval v)->view->forms->rLatexFileFileSelectorField->value
						(eval v)->model->sOutDir 			= (eval v)->view->forms->rOutDirFileSelectorField->value
						(eval v)->model->xShapesPerFile 	= (eval v)->view->forms->rShapesPerFileIntField->value
						(eval v)->model->sLatexCompiler 	= (eval v)->view->forms->rLatexCompilerStringField->value
						(eval v)->model->bMake 				= (eval v)->view->forms->rMakeBooleanButton->value
						(eval v)->model->bDebug 			= (eval v)->view->forms->rDebugBooleanButton->value
						(eval v)->model->nGridSize 			= (eval v)->view->forms->rGridSizeFloatForm->value
						(eval v)->model->bSplitLayers 		= (eval v)->view->forms->rSplitLayerBooleanButton->value

						(when (eval v)->model->fCheckInout(v)

							(eval v)->model->fWriteTikZ(v)
						);when
					);lambda
					fExecuteML2TIKZ
				);putpropq

				(hiDisplayForm (eval v)->view->forms->rML2TIKZLayoutForm)
			else

				(eval v)->model->sLayersLatexFile = sLayersLatexFile
				(eval v)->model->oSourceCellView = oCellView
				(eval v)->model->sOutDir = sOutDir
				(eval v)->model->xShapesPerFile = xShapesPerFile
				(eval v)->model->sLatexCompiler =sLatexCompiler
				(eval v)->model->bMake = bMake
				(eval v)->model->bDebug = bDebug
				(eval v)->model->nGridSize = nGridSize
				(eval v)->model->bSplitLayers = bSplitLayers

				(when (eval v)->model->fCheckInout(v)

					(eval v)->model->fWriteTikZ(v)
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
	(hiInsertBannerMenu
		args->window
		(ML2TIKZCreateLayoutPulldownMenu)
		(length (hiGetBannerMenus args->window))
	);hiInsertBannerMenu
);procedure

(deRegUserTriggers "maskLayout" nil nil 'ML2TIKZUserPostInstallTrigger)
(deRegUserTriggers "maskLayoutXL" nil nil 'ML2TIKZUserPostInstallTrigger)
