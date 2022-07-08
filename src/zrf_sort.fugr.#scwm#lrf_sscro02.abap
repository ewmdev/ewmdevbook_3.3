*----------------------------------------------------------------------*
***INCLUDE /SCWM/LRF_SSCRO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  loop_output  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE loop_output OUTPUT.
  PERFORM loop_output.
ENDMODULE.                 " loop_output  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  loop_output
*&---------------------------------------------------------------------*
*       Display row of table in step-loop
*----------------------------------------------------------------------*
FORM loop_output .

  DATA lv_index      TYPE i.
  DATA lv_tabline    TYPE i.
  DATA lv_line       TYPE i.
  DATA lv_attrib_req TYPE /scwm/de_screlm_attrib.
  DATA lv_attrib_inp TYPE /scwm/de_screlm_attrib.
  DATA lv_attrib_inv TYPE /scwm/de_screlm_attrib.
  DATA lv_field      TYPE text60.

* Number of step-loop rows
  /scwm/cl_rf_dynpro_srvc=>set_loopc( sy-loopc ).
  lv_line = /scwm/cl_rf_bll_srvc=>get_cursor_line( ).

  IF lv_line > 0.
    lv_field = /scwm/cl_rf_bll_srvc=>get_field( ).
    IF lv_field IS NOT INITIAL.
      gv_field = lv_field.
    ENDIF.
    SET CURSOR FIELD gv_field LINE lv_line.
  ENDIF.

* First line to be displayed
  lv_tabline = /scwm/cl_rf_bll_srvc=>get_line( ).

* Index of current line
  lv_index = lv_tabline + sy-stepl - 1.

* Display current line
  READ TABLE <gt_scr> INTO <gs_scr> INDEX lv_index.

  IF sy-subrc <> 0.
*   Deactivate unused rows of step-loop
    LOOP AT SCREEN.
      screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
      MODIFY SCREEN.
    ENDLOOP.
    EXIT.
  ELSE.
    LOOP AT SCREEN.
      lv_attrib_req =
         /scwm/cl_rf_bll_srvc=>get_screlm_req_attrib_from_bll(
                                iv_screlm_name = screen-name
                                iv_index       = lv_index ).
      lv_attrib_inp =
         /scwm/cl_rf_bll_srvc=>get_screlm_inp_attrib_from_bll(
                                iv_screlm_name = screen-name
                                iv_index       = lv_index ).
      lv_attrib_inv =
         /scwm/cl_rf_bll_srvc=>get_screlm_inv_attrib_from_bll(
                                iv_screlm_name = screen-name
                                iv_index       = lv_index ).
*     'Invisible' attribute
      IF lv_attrib_inv IS NOT INITIAL.
        screen-invisible = lv_attrib_inv.
        IF lv_attrib_inv = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*         Field invisible -> no input & no required
          screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
          screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
      CHECK lv_attrib_inv <> /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*     'Input' attribute
      IF lv_attrib_inp IS NOT INITIAL.
        screen-input = lv_attrib_inp.
        IF lv_attrib_inp = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*         Input field -> visible
          screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
      CHECK lv_attrib_inp <> /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
*     'Required' attribute
      IF lv_attrib_req IS NOT INITIAL.
        screen-required = lv_attrib_req.
        IF lv_attrib_req = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*         Required field -> visible and input
          screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
          screen-input     = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
    LOOP AT SCREEN.
      IF screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
        screen-group1   = /scwm/cl_rf_dynpro_srvc=>c_group1_input.
        screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        MODIFY SCREEN.
      ENDIF.
      IF screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
        screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
        screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " loop_output
