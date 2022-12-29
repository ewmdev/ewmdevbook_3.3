*----------------------------------------------------------------------*
***INCLUDE /SCWM/LRF_SSCRO03 .
*----------------------------------------------------------------------*
MODULE loop_scrolling_set OUTPUT.
  PERFORM loop_scrolling_set.
ENDMODULE.                    "loop_scrolling_set
*&---------------------------------------------------------------------*
*&      Form  loop_scrolling_set
*&---------------------------------------------------------------------*
*       Activate/Deactivate PGUP/PGDN pushbuttons
*----------------------------------------------------------------------*
FORM loop_scrolling_set .

* data
  DATA lv_lines     TYPE i.
  DATA lv_tabline   TYPE i.
  DATA lv_last_line TYPE i.
  DATA lv_loopc     TYPE i.

  IF /scwm/cl_rf_bll_srvc=>get_design_mode( ) = abap_true.
    RETURN.
  ENDIF.


* Lines of table
  DESCRIBE TABLE <gt_scr> LINES lv_lines.
  IF lv_lines <= 1.
    PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGDN'.
    PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGUP'.
    EXIT.
  ENDIF.

* First line of step line
  lv_tabline = /scwm/cl_rf_bll_srvc=>get_line( ).
* Lines in step-loop
  lv_loopc   = /scwm/cl_rf_dynpro_srvc=>get_loopc( ).

  IF lv_lines >= lv_tabline.
*   Index of table row at the end of step-loop
    lv_last_line = lv_tabline + lv_loopc - 1.
    IF lv_lines <= lv_last_line.
*     Last page displayed -> disable PGDN
      PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGDN'.
    ELSE.
*     display page down if there are more rows then we can display
      PERFORM reactivate USING '/SCWM/S_RF_SCRELM-PGDN'.
    ENDIF.
  ENDIF.

  IF lv_tabline = 1.
*   First page displayed -> disable PGUP
    PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGUP'.
  ELSE.
*   display page up if not on the first screen
    PERFORM reactivate USING '/SCWM/S_RF_SCRELM-PGUP'.
  ENDIF.

ENDFORM.                    " loop_scrolling_set
