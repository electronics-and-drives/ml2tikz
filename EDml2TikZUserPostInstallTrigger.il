/*=============================================================================*
*
*   EDml2TikZUserPostInstallTrigger
*
*   Purpose:    Register ml2TikZ as menu in the layout editor
*
*   Author:     Matthias Schweikardt
*   Email:      matthias.schweikardt@reutlingen-university.de
*
*   Lint: IQ score is 100 (best is 100) 
*         {sklint ?file "EDml2TikZUserPostInstallTrigger.il"}
*
*   Globals:
*    - Functions:
*     o EDml2TikZCreateLayoutPulldownMenu
*     o EDml2TikZUserPostInstallTrigger
*
*   Revision:   2022-09-25 Created
*
*   Copyright 2022, Reutlingen University, Electronics & Drives 
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