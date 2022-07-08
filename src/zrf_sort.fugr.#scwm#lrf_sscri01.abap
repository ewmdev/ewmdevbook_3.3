*----------------------------------------------------------------------*
***INCLUDE /SCWM/LRF_SSCRI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_sscr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_sscr INPUT.

  PERFORM user_command_sscr.

ENDMODULE.                 " USER_COMMAND_sscr  INPUT
*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_sscr
*&---------------------------------------------------------------------*
FORM user_command_sscr .

  STATICS sv_dbl_clear     TYPE xfeld.
  STATICS sv_field_clr(60) TYPE c.

  DATA lv_fcode           TYPE /scwm/de_fcode.
  DATA lt_data            TYPE abap_func_parmbind_tab.
  DATA ls_data            TYPE abap_func_parmbind.
  DATA lv_index           TYPE i.
  DATA lv_field(60)       TYPE c.
  DATA lv_tabline         TYPE i.
  DATA lv_lines           TYPE i.
  DATA lv_loopc           TYPE i.
  DATA lv_dbl_clear       TYPE xfeld.
  DATA lv_flg_field       TYPE xfeld.
  DATA lt_param           TYPE /scwm/tt_param_name.
  DATA lv_param           TYPE /scwm/de_param_name.
  DATA lv_param_structure TYPE tabname.
  DATA lv_line            TYPE i.
  DATA lv_tabname         TYPE tabname.                     "#EC NEEDED
  DATA lv_fieldname       TYPE fieldname.
  DATA lv_page_yes        TYPE c.
  DATA lv_value_inp       TYPE c.
  DATA lv_field_found     TYPE xfeld.

  FIELD-SYMBOLS: <ls_data> TYPE any,
                 <ls_scr>  TYPE any,
                 <lv>      TYPE any.

* Once displayed message line is cleared
  CLEAR /scwm/s_rf_screlm-msgtx.

* Get function code
  lv_fcode         = /scwm/cl_rf_bll_srvc=>get_okcode( ).

  IF lv_fcode = 'ENTER'.
    DATA: lv_field_long TYPE /scwm/de_fieldname_60,
          lv_field_value TYPE text256.
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

  lv_dbl_clear = sv_dbl_clear.
  sv_dbl_clear = abap_false.

  GET CURSOR FIELD lv_field.

  IF lv_field IS NOT INITIAL.
    /scwm/cl_rf_bll_srvc=>set_act_field( lv_field ).
  ENDIF.

  IF /scwm/cl_rf_bll_srvc=>get_navigation_check( ) = abap_true.
*   This loop executed only, if no shortcut is set for the pres. dvc.
    LOOP AT SCREEN.
      IF screen-name = lv_field.
        lv_flg_field = abap_true.
        CONTINUE.
      ENDIF.
      CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
            lv_flg_field = abap_true.
      CHECK screen-name <> '/SCWM/S_RF_SCRELM-PGDN' AND
            screen-name <> '/SCWM/S_RF_SCRELM-PGUP'.
      ASSIGN (screen-name) TO <lv>.
      IF sy-subrc IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      CHECK <lv> IS INITIAL.
      /scwm/cl_rf_bll_srvc=>set_fcode(
           /scwm/cl_rf_bll_srvc=>c_fcode_unknown ).
      EXIT.
    ENDLOOP.
    lv_fcode = /scwm/cl_rf_bll_srvc=>get_okcode( ).
    IF lv_fcode = /scwm/cl_rf_bll_srvc=>c_fcode_unknown.
      /scwm/cl_rf_bll_srvc=>set_last_fld( abap_false ).
    ELSE.
      /scwm/cl_rf_bll_srvc=>set_last_fld( abap_true ).
    ENDIF.
  ELSE.
    /scwm/cl_rf_bll_srvc=>set_last_fld( abap_false ).
  ENDIF.

  /scwm/cl_rf_bll_srvc=>set_field( lv_field ).

  IF lv_fcode = /scwm/cl_rf_bll_srvc=>c_fcode_clear OR
     lv_fcode = /scwm/cl_rf_bll_srvc=>c_fcode_clear_all.
*   'CLEAR'-function code
    IF ( lv_dbl_clear = abap_false OR
         lv_field <> sv_field_clr ) AND
       lv_fcode     = /scwm/cl_rf_bll_srvc=>c_fcode_clear.
*     Pressed once - clear current field (if it's input field)
      LOOP AT SCREEN.
        CHECK screen-name = lv_field                 AND
         screen-input     =
               /scwm/cl_rf_dynpro_srvc=>c_attrib_on  AND
         screen-invisible =
               /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        ASSIGN (screen-name) TO <lv>.
        CLEAR <lv>.
        EXIT.
      ENDLOOP.
      sv_dbl_clear = abap_true.
      sv_field_clr = lv_field.
    ELSEIF lv_fcode = /scwm/cl_rf_bll_srvc=>c_fcode_clear_all OR
           /scwm/cl_rf_bll_srvc=>get_flg_clear_all( ) = abap_true.
      DATA lv_first_field TYPE xfeld.
      DATA lv_field_name  TYPE text60.
      CLEAR lv_first_field.
*     Clear all input fields on the screen
      DATA: lv_valinp_field TYPE /scwm/de_valinp_fldname,
            lv_struc        TYPE /scwm/de_valinp_fldname,   "#EC NEEDED
            lv_data_entry   TYPE /scwm/de_data_entry,
            lt_valid_prf    TYPE /scwm/tt_valid_prf_ext.
      DATA: lt_fcode        TYPE /scwm/tt_fcode.
      FIELD-SYMBOLS <ls_valid_prf> TYPE /scwm/s_valid_prf_ext.

*     Check if we work with a PbV device
      lv_data_entry = /scwm/cl_rf_bll_srvc=>get_data_entry( ).

      IF lv_data_entry = wmegc_data_entry_voice.
        CALL METHOD /scwm/cl_rf_bll_srvc=>get_valid_prf
          RECEIVING
            rt_valid_prf = lt_valid_prf.

*       Clear screen prompt otherwise it will be repeated
        CLEAR /scwm/s_rf_screlm_pbv-scr_prompt.
        /scwm/cl_rf_bll_srvc=>set_screlm_pbv( /scwm/s_rf_screlm_pbv ).
      ENDIF.

      LOOP AT SCREEN.
*       On Pick-by-Voice we also clear the already validated fields
*       Keep in mind that validation field table is NOT changed
        IF lv_data_entry = wmegc_data_entry_voice.

*         Check if screen field is validation field
          SPLIT screen-name AT '-' INTO lv_struc lv_valinp_field.

          READ TABLE lt_valid_prf ASSIGNING <ls_valid_prf>
            WITH KEY valinp_fldname = lv_valinp_field.
          IF sy-subrc = 0.
*           Field is validation field -> we clear the value
*           Independent if field is open or closed
*           If it is closed it will be opened again.
          ELSE.
*           Normal input fields
*           Check if SCRELM_ATTRIB entry for Input Off exists
              CALL METHOD /scwm/cl_rf_bll_srvc=>get_screlm_inp_attrib_from_bll
                EXPORTING
                  iv_screlm_name = screen-name
                RECEIVING
                  rv_value       = lv_value_inp.
              IF lv_value_inp = '0'.
*             Manually switched off field
                /scwm/cl_rf_bll_srvc=>set_screlm_input_on(
                    screen-name ).
              ELSE.
                IF screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
*               Closed field like text
                CONTINUE.
              ELSE.
*               Open input field; will be cleared
              ENDIF.
            ENDIF.
          ENDIF.
*         Check if 'LIST' fcode is switched off. If yes, switch it on again
          CALL METHOD /scwm/cl_rf_bll_srvc=>get_fcode_settings
            RECEIVING
              rt_fcode = lt_fcode.
          READ TABLE lt_fcode
            WITH KEY table_line = wmegc_rf_fcode_list
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            CALL METHOD /scwm/cl_rf_bll_srvc=>set_fcode_on
              EXPORTING
                iv_fcode = wmegc_rf_fcode_list.
          ENDIF.
        ELSE.
*         Old logic
          CHECK screen-input      =
                  /scwm/cl_rf_dynpro_srvc=>c_attrib_on  AND
                screen-invisible  =
                  /scwm/cl_rf_dynpro_srvc=>c_attrib_off AND
                screen-display_3d =
                  /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
        ENDIF.
        ASSIGN (screen-name) TO <lv>.
        CLEAR <lv>.
*       Set the first field otherwise cursor is not positioned on
*         first field but on the actual field, if the screen contains
*         only input fields (no validation fields).
        IF lv_first_field IS INITIAL.
          lv_field_name = screen-name.
          CALL METHOD /scwm/cl_rf_bll_srvc=>set_field
            EXPORTING
              iv_field = lv_field_name.
          lv_first_field = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Check shortcut value if not initial.
*  IF /scwm/s_rf_screlm-shortcut IS NOT INITIAL.
*    lv_shortcut = /scwm/cl_rf_bll_srvc=>get_shortcut( ).
*    IF lv_shortcut <> /scwm/s_rf_screlm-shortcut.
*      /scwm/s_rf_screlm-shortcut = lv_shortcut.
*    ENDIF.
*  ENDIF.
* The code above was replaced with this CLEAR below.
* Reason: shortcut field is not cleared, if the customer use own
* display profile where the screens are copied into 1 function group
* The problem the TABLES for /scwm/s_rf_screlm.
  CLEAR /scwm/s_rf_screlm-shortcut.

  /scwm/cl_rf_bll_srvc=>set_screlm( /scwm/s_rf_screlm ).

* Save application data
  lt_data    = /scwm/cl_rf_bll_srvc=>get_data( ).
  lv_tabline = /scwm/cl_rf_bll_srvc=>get_line( ).

  IF lv_tabline = 0.
    lv_tabline = 1.
  ENDIF.

  lt_param = /scwm/cl_rf_bll_srvc=>get_screen_param( ).

* Save screen parameters in lt_data
  lv_loopc = /scwm/cl_rf_dynpro_srvc=>get_loopc( ).

  LOOP AT lt_param INTO lv_param.
    READ TABLE lt_data INTO ls_data
         WITH KEY kind = abap_func_changing
                  name = lv_param.
    lv_index = sy-tabix.
    lv_param_structure = /scwm/cl_rf_bll_srvc=>get_param_structure(
                             lv_param ).
    ASSIGN (lv_param_structure) TO <ls_scr>.
    IF sy-subrc = 0.
      IF /scwm/cl_rf_bll_srvc=>get_param_tabletype( lv_param )
              IS INITIAL.
*       Structure is known to the current screen program
        ASSIGN ls_data-value->* TO <ls_data>.
        <ls_data> = <ls_scr>.
      ELSE.
*       Table structure is visible in the current screen program ->
        IF lv_loopc = 0.
*         Table not presented in step-loop -> save current line
          IF <gs_scr> IS ASSIGNED AND <gt_scr> IS ASSIGNED.
            MODIFY <gt_scr> FROM <gs_scr> INDEX lv_tabline.
          ENDIF.
        ENDIF.
      ENDIF.
      MODIFY lt_data FROM ls_data INDEX lv_index.
    ENDIF.
  ENDLOOP.

* Set changed application data
  /scwm/cl_rf_bll_srvc=>set_data( lt_data ).

* Propose navigation: to the next field or leave on the
* current field(if required and not filled)
* If F8 (List is pressed) the navigation has to work
* on a defferent way (before it stepped always one)
  IF lv_fcode NE /scwm/cl_rf_bll_srvc=>c_fcode_list.
    lv_field = /scwm/cl_rf_bll_srvc=>get_field_required( ).
  ELSE.
    LOOP AT SCREEN.
      IF screen-name = lv_field AND
         screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        /scwm/cl_rf_bll_srvc=>set_fcode(
            /scwm/cl_rf_bll_srvc=>c_fcode_unknown ).
        EXIT.
      ENDIF.
    ENDLOOP.
*   It remains on the actual field -> next requires will
*   be really the next one
    CLEAR lv_field.

* set value help list when enable editing
    DATA: lv_char40          TYPE /scwm/de_rf_text,
          lt_hu_pmat_type    TYPE /scwm/tt_rf_mat_hutyp,
          ls_hu_pmat_type    TYPE /SCWM/S_RF_MAT_HUTYP.

    IF ( /scwm/cl_rf_bll_srvc=>get_step( ) = 'IVHU' OR /scwm/cl_rf_bll_srvc=>get_step( ) = 'IVHUHU' )
    AND /scwm/cl_rf_bll_srvc=>get_field( ) = '/SCWM/S_RF_INVENTORY_HEAD-HU_PMAT'.
      IF /scwm/cl_rf_bll_srvc=>get_listbox( ) IS INITIAL.
        CALL FUNCTION '/SCWM/RF_HU_IVHU_PMLIST'
        IMPORTING
          et_hu_type = lt_hu_pmat_type.

        LOOP AT lt_hu_pmat_type INTO ls_hu_pmat_type.
          CONCATENATE ls_hu_pmat_type-matnr ls_hu_pmat_type-maktx INTO lv_char40 SEPARATED BY '  '.
* insert packaging material
          /scwm/cl_rf_bll_srvc=>insert_listbox(
          iv_fieldname = '/SCWM/S_RF_INVENTORY_HEAD-HU_PMAT'
          iv_value = ls_hu_pmat_type-matnr
          iv_text = lv_char40 ).
        ENDLOOP.
      ENDIF.
    ENDIF.

  ENDIF.

  IF lv_field IS NOT INITIAL AND
     lv_field <> '****'.
    ASSIGN (lv_field) TO <lv>.
    IF <lv> IS ASSIGNED.
      IF <lv> IS NOT INITIAL OR
         <lv> IS INITIAL AND
         /scwm/cl_rf_bll_srvc=>get_flg_input_required( ) = abap_false.

        lv_flg_field = abap_false.
        /scwm/cl_rf_bll_srvc=>clear_flg_input_required( ).
        LOOP AT SCREEN.
          CHECK screen-name <> '/SCWM/S_RF_SCRELM-PGUP' AND
                screen-name <> '/SCWM/S_RF_SCRELM-PGDN'.
          IF screen-name = lv_field.
            lv_flg_field = abap_true.
          ELSEIF lv_flg_field = abap_true AND
            ( screen-input  = /scwm/cl_rf_dynpro_srvc=>c_attrib_on OR
              screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_input ).
            IF screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_input.
              lv_line = /scwm/cl_rf_bll_srvc=>get_cursor_line( ).
              lv_tabline = /scwm/cl_rf_bll_srvc=>get_line( ).
*           Index of current line
              lv_index = lv_tabline + lv_line - 1.
              READ TABLE <gt_scr> ASSIGNING <gs_scr> INDEX lv_index.
              SPLIT screen-name AT '-' INTO lv_tabname lv_fieldname.
              ASSIGN COMPONENT lv_fieldname OF STRUCTURE <gs_scr>
                               TO <lv>.
            ELSE.
              ASSIGN (screen-name) TO <lv>.
            ENDIF.
            CHECK <lv> IS INITIAL.
            /scwm/cl_rf_bll_srvc=>set_flg_input_possible( screen-name ).
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

* Restore required attribute of the screen elements
  LOOP AT SCREEN.
    IF screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
      screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      MODIFY SCREEN.
    ENDIF.
*   Check if we have PAgeUp and PageDn on the screen
    IF screen-name(20) = '/SCWM/S_RF_SCRELM-PG'.
      lv_page_yes = 'X'.
    ENDIF.
  ENDLOOP.

* screen contains required fields?
  LOOP AT SCREEN.
    IF screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
        screen-name(20) <> '/SCWM/S_RF_SCRELM-PG'.
      ASSIGN (screen-name) TO <lv>.
      IF <lv> IS INITIAL.
        IF screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
          /scwm/cl_rf_bll_srvc=>set_flg_input_required( screen-name ).
          EXIT.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF <gt_scr> IS ASSIGNED AND
    lv_page_yes IS NOT INITIAL.
*   Process function codes PGUP/PGDN
    CASE lv_fcode.
      WHEN /scwm/cl_rf_bll_srvc=>c_fcode_prev_pg.
*       Process page down (of the table lines)
        IF lv_tabline > 1.
          IF lv_loopc > 1.
            SUBTRACT lv_loopc FROM lv_tabline.
            IF lv_tabline < 1.
              lv_tabline = 1.
            ENDIF.
          ELSE.
            SUBTRACT 1 FROM lv_tabline.
          ENDIF.
          /scwm/cl_rf_bll_srvc=>set_line( lv_tabline ).
        ENDIF.
      WHEN /scwm/cl_rf_bll_srvc=>c_fcode_next_pg.
*       Get number of table lines
        DESCRIBE TABLE <gt_scr> LINES lv_lines.
*       Process page up (of the table lines)
        IF lv_tabline < lv_lines.
          IF lv_loopc > 1.
            ADD lv_loopc TO lv_tabline.
            IF lv_tabline > lv_lines.
              lv_tabline = lv_tabline - lv_loopc.
            ENDIF.

            IF lv_tabline < 1.
              lv_tabline = 1.
            ENDIF.
          ELSE.
            ADD 1 TO lv_tabline.
          ENDIF.
          /scwm/cl_rf_bll_srvc=>set_line( lv_tabline ).
        ENDIF.
    ENDCASE.
  ENDIF.

ENDFORM.                    "user_command_sscr
