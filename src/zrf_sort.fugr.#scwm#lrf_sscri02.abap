*----------------------------------------------------------------------*
***INCLUDE /SCWM/LRF_SSCRI02 .
**---------------------------------------------------------------------*
*  MODULE loop_input INPUT
*---------------------------------------------------------------------*
*  Save input made in step-loop
*---------------------------------------------------------------------*
MODULE loop_input INPUT.

  PERFORM loop_input.

ENDMODULE.                 " loop_input  INPUT
*&--------------------------------------------------------------------*
*&      Form  loop_input
*&--------------------------------------------------------------------*
FORM loop_input.

*- data
  DATA lv_index     TYPE i.
  DATA lv_line      TYPE i.
  DATA lv_tabname   TYPE tabname.   "#EC NEEDED
  DATA lv_fieldname TYPE fieldname.
  DATA lv_field(60) TYPE c.
  DATA lv_fcode     TYPE /scwm/de_fcode.   "#EC NEEDED
  DATA lv_loopc     TYPE i.

*- field-symbols
  FIELD-SYMBOLS: <lv>     TYPE ANY,
                 <lv_scr> TYPE ANY,
                 <ls_scr> TYPE ANY.

* Calculate index of current table line
  lv_index = /scwm/cl_rf_bll_srvc=>get_line( ) + sy-stepl - 1.
  READ TABLE <gt_scr> ASSIGNING <ls_scr> INDEX lv_index.

  IF sy-subrc <> 0.
    EXIT.
  ENDIF.

  LOOP AT SCREEN.
    CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
    ASSIGN (screen-name) TO <lv_scr>.
    SPLIT screen-name AT '-' INTO lv_tabname lv_fieldname.
    ASSIGN COMPONENT lv_fieldname OF STRUCTURE <ls_scr> TO <lv>.
    <lv> = <lv_scr>.
  ENDLOOP.

* Check number of table lines
  lv_loopc = /scwm/cl_rf_dynpro_srvc=>get_loopc( ).
  if lv_loopc = 0.  "Step-loop but number of lines = 0 -> not good
    /scwm/cl_rf_dynpro_srvc=>set_loopc( sy-loopc ).
  endif.

* Save current line
  MODIFY <gt_scr> FROM <ls_scr> INDEX lv_index.

* Get cursor line
  GET CURSOR FIELD lv_field LINE lv_line.

  IF lv_field IS NOT INITIAL.
    /scwm/cl_rf_bll_srvc=>set_act_field( lv_field ).
  ENDIF.

  lv_fcode = /scwm/cl_rf_bll_srvc=>get_fcode_setting( ).

  /scwm/cl_rf_bll_srvc=>set_cursor_line( lv_line ).

* Get function code
  lv_fcode         = /scwm/cl_rf_bll_srvc=>get_okcode( ).

  "Write RF log for field input in step-loops
  IF lv_fcode = 'ENTER'.
    DATA: lv_field_long  TYPE /scwm/de_fieldname_60,
          lv_field_value TYPE text256,
          lv_field_found TYPE xfeld.
    DATA lo_badi       TYPE REF TO /scwm/ex_rf_logging.
    DATA(lv_lgnum) = /scwm/cl_rf_bll_srvc=>get_lgnum( ).

    TRY.
        GET BADI lo_badi
          FILTERS
            lgnum = lv_lgnum.

        IF lo_badi IS BOUND.
          CLEAR lv_field_found.
          GET CURSOR FIELD lv_field_long.
          LOOP AT SCREEN.
            CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
            IF screen-name = lv_field_long.
              ASSIGN (screen-name) TO <lv>.
              IF sy-subrc = 0.
                "Also initial values are valid
                lv_field_value = <lv>.
                lv_field_found = abap_true.
              ENDIF.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF lv_field_found = abap_true.
            CALL BADI lo_badi->log_rf_field_input
              EXPORTING
                iv_field    = lv_field_long
                iv_field_value = lv_field_value.
          ENDIF.
        ENDIF.
      CATCH cx_badi.                                      "#EC NO_HANDLER
    ENDTRY.
  ENDIF.


* Restore required attribute of the screen elements
  IF screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
    screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
    ASSIGN (screen-name) TO <lv>.
    IF <lv> IS INITIAL AND
       /scwm/cl_rf_bll_srvc=>get_flg_input_required( ) =
       /scmb/cl_c=>boole_false.
      /scwm/cl_rf_bll_srvc=>set_flg_input_required( screen-name ).
    ENDIF.
    MODIFY SCREEN.
  ENDIF.

ENDFORM.                    "loop_input
