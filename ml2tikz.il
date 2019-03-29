/*============================================================*
*
*   ml2tikz
*
*   Purpose:    maskLayout to tikzpicture converter
*
*   Author:     Matthias Schweikardt
*   Email:      matthias.schweikardt@reutlingen-university.de
*
*   Revision:   0.0.1       (2019-03-29)
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
		(oCellView (geGetEditCellView))
		(sOutDir "./")
		(sLatexCompiler "pdflatex")
		(sLayersLatexFile nil)
		(bGraphicalMode nil)
		(bDebug nil)
		(xShapesPerFile 5e3)
		(bExecute t)
	)

	(let (v)

		(setq v	(gensym))
		(set v (list nil))

		(eval v)->model = (list nil)
		(eval v)->temp = (list nil)
		(eval v)->temp->sStartTime = (buildString (parseString (getCurrentTime) ": ") "_")
		(eval v)->model->sLatexCompiler =sLatexCompiler
		(eval v)->model->bExecute = bExecute
		(eval v)->model->bDebug = bDebug

		;fReadInLayersLatexFile
		(putpropq 
		    (eval v)->model
			(lambda (v)
				(let (s pPort)

					(eval v)->model->lLayers = nil

					(when 
						(and
							(stringp (eval v)->model->sLayersLatexFile )
							(isFile (eval v)->model->sLayersLatexFile )
							(isReadable (eval v)->model->sLayersLatexFile )
						);and

						pPort = (infile (eval v)->model->sLayersLatexFile )

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
				(let (sStartPhrase sEndPhrase pCombinedTikZ pScript pTikZ (i 1) (xShapeCount 0))
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
						32 			;x_levels
						t 			;g_flattenPCells
						nil 		;g_preservePins
						nil 		;g_preserveRODobjs
						nil 		;g_delDetachedBlockages
						nil 		;g_preservePinFigs
						t			;g_flattenVias
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
										(setof 
											x 
											(eval v)->model->oFlattenCellView~>shapes 
											(equal x~>lpp lLayer)
										);setof
									);dbLayerOr
								);length
							);plus
							xNumOfShapes
						);putpropq
					);foreach

					(when (eval v)->model->xNumOfShapes>(eval v)->model->xShapesPerFile 

						(eval v)->model->xShapesPerFile = (ceiling (eval v)->model->xNumOfShapes/(ceiling 1.0*(eval v)->model->xNumOfShapes/(eval v)->model->xShapesPerFile ))
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

					(setq
						sStartPhrase
						(strcat
							"\\documentclass{standalone}\n"
							"\\usepackage{xcolor}\n"
							"\\usepackage{tikz}\n"
							"\\usepackage{graphicx}\n"
							"\\input{\"" (eval v)->model->sLayersLatexFile "\"}\n"
							"\\begin{document}\n"
							"\\begin{tikzpicture}[x=1cm,y=1cm]\n"
							(lsprintf
								"\\draw[line width = 0mm,white] (%L,%L) rectangle (%L,%L);\n" 
								(xCoord (lowerLeft (eval v)->model->oCombinedCellView~>bBox))-0.01
								(yCoord (lowerLeft (eval v)->model->oCombinedCellView~>bBox))-0.01
								(xCoord (upperRight (eval v)->model->oCombinedCellView~>bBox))+0.01
								(yCoord (upperRight (eval v)->model->oCombinedCellView~>bBox))+0.01
							);lsprintf
						);strcat
					);setq

					(setq
						sEndPhrase
						(strcat
							"\\end{tikzpicture}\n"
							"\\end{document}\n"
						);strcat
					);setq

					(setq 
						pTikZ 
						(outfile 
							(strcat 
								(eval v)->model->sOutDir
								"layout_0.tex"
							);strcat
						);outfile
					);setq

					(fprintf pTikZ sStartPhrase)

					(setq 
						pCombinedTikZ 
						(outfile 
							(strcat 
								(eval v)->model->sOutDir
								(eval v)->model->oSourceCellView~>libName
								"_"
								(eval v)->model->oSourceCellView~>cellName
								"_"
								(eval v)->model->oSourceCellView~>viewName
								".tex"
							);strcat
						);outfile
					);setq

					(fprintf 
						pCombinedTikZ 
						"%s"
						(strcat
							"\\documentclass{standalone}\n"
							"\\usepackage{tikz}\n"
							"\\usepackage{graphicx}\n"
							"\\begin{document}\n"
							"\\begin{tikzpicture}\n"
						);strcat
					);fprintf

					(fprintf pCombinedTikZ "\\node at (0,0) {\\includegraphics{layout_0.pdf}};\n")
					
					(setq 
						pScript 
						(outfile 
							(strcat 
								(eval v)->model->sOutDir
								"layout2tikz.sh"
							);strcat
						);outfile
					);setq
					(fprintf pScript "#!/bin/sh\n")
					(fprintf pScript (strcat (eval v)->model->sLatexCompiler " layout_0.tex\n"))
					(foreach lLayer (eval v)->model->lLayers

						(foreach oShape (setof x (eval v)->model->oCombinedCellView~>shapes x~>lpp==lLayer)

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

								(setq 
									pTikZ 
									(outfile 
										(strcat 
											(eval v)->model->sOutDir
											"layout_"
											(lsprintf "%L" i)
											".tex"
										);strcat
									);outfile
								);setq
								(fprintf pCombinedTikZ "\\node at (0,0) {\\includegraphics{layout_%L.pdf}};\n" i)
								(fprintf pScript (strcat (eval v)->model->sLatexCompiler " layout_" (lsprintf "%L" i) ".tex\n"))
								(fprintf pTikZ "%s" sStartPhrase)

								i = i+1
								xShapeCount = 0
							);when
						);foreach
					);foreach
					(fprintf pTikZ "%s" sEndPhrase)
					(fprintf pCombinedTikZ "%s" sEndPhrase)
					(fprintf 
						pScript 
						(strcat 
							(eval v)->model->sLatexCompiler 
							" " 
							(eval v)->model->oSourceCellView~>libName 
							"_" 
							(eval v)->model->oSourceCellView~>cellName 
							"_" 
							(eval v)->model->oSourceCellView~>viewName  
							".tex\n"
						);strcat
					);fprintf
					(close pTikZ)
					(close pScript)
					(close pCombinedTikZ)
					(shell (strcat "chmod u+x " (eval v)->model->sOutDir "layout2tikz.sh"))
					(dbClose (eval v)->model->oCombinedCellView)

					(when (eval v)->model->bExecute 
						(shell (strcat "sh " (eval v)->model->sOutDir "layout2tikz.sh"))
					);when
					(if (eval v)->model->bDebug then

						(dbClose (eval v)->model->oFlattenCellView)
						(dbClose (eval v)->model->oCombinedCellView)
					else
						(dbDeleteObject (eval v)->model->oFlattenCellView)
						(dbDeleteObject (eval v)->model->oCombinedCellView)
					);if
				);let
			);lambda
			fWriteTikZ
		);putpropq


		(if 
			(and
				oCellView
				(dbIsId oCellView)
				(equal "maskLayout" oCellView~>cellViewType)
			);and

			then

			(if bGraphicalMode then
				nil
			else

				(eval v)->model->sLayersLatexFile = sLayersLatexFile

				(eval v)->model->oSourceCellView = oCellView

				(eval v)->model->sOutDir = sOutDir

				(eval v)->model->xShapesPerFile = xShapesPerFile

				(unless (fixp (eval v)->model->xShapesPerFile)

					(unless (eval v)->model->xShapesPerFile > 1

						(eval v)->model->xShapesPerFile = 5e3
					);unless	
				);unless

				(if (eval v)->model->fReadInLayersLatexFile(v) then

					(if (isDir (eval v)->model->sOutDir) && (isWritable (eval v)->model->sOutDir)  then

						(eval v)->model->sOutDir = (strcat "/" (buildString (parseString (simplifyFilename (eval v)->model->sOutDir) "/") "/") "/")
						(eval v)->model->fWriteTikZ(v)

					else
						(fprintf errport "*layout2TikZ* No valid output directory is specified\n")
					);if 
				else
					(fprintf errport "*layout2TikZ* No valid layers in %L\n" (eval v)->model->sLayersLatexFile)
				);if
			);if
		else
			(fprintf errport "*layout2TikZ* No valid maskLayout view found\n")
		);if
	);let
);defun
