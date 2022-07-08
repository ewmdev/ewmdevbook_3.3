*----------------------------------------------------------------------*
***INCLUDE /SCWM/LRF_SSCRO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_sscr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_sscr OUTPUT.
  PERFORM status_sscr
          USING /scmb/cl_c=>boole_false.
ENDMODULE.                 " STATUS_sscr  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_sscr_loop  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_sscr_loop OUTPUT.

  DATA:
    gv_field TYPE screen-name.   "#EC DECL_MODUL

  CLEAR gv_field.
  PERFORM status_sscr
          USING /scmb/cl_c=>boole_true.
ENDMODULE.                 " STATUS_sscr_loop  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  status_sscr
*&---------------------------------------------------------------------*
* pass structures to the screen
* set screen attributes
*----------------------------------------------------------------------*
*  -->  iv_flg_loop Indicator: screen with step-loop
*----------------------------------------------------------------------*
FORM status_sscr USING iv_flg_loop TYPE xfeld.

  DATA lt_data            TYPE abap_func_parmbind_tab.
  DATA ls_data            TYPE abap_func_parmbind.
  DATA lv_tabname         TYPE tabname.
  DATA lv_tabline         TYPE i.
  DATA lv_lines           TYPE i.
  DATA lt_verif_prf       TYPE /scwm/tt_valid_prf_ext.
  DATA ls_verif_prf       TYPE /scwm/s_valid_prf_ext.
  DATA lv_flg_cursor      TYPE xfeld.
  DATA lv_field(60)       TYPE c.
  DATA lv_field_appl(60)  TYPE c.
  DATA lv_fldname(60)     TYPE c.
  DATA lv_flg             TYPE xfeld.
  DATA lv_attrib_req      TYPE /scwm/de_screlm_attrib.
  DATA lv_attrib_inp      TYPE /scwm/de_screlm_attrib.
  DATA lv_attrib_inv      TYPE /scwm/de_screlm_attrib.
  DATA lv_param_name      TYPE /scwm/de_param_name.
  DATA lt_param           TYPE /scwm/tt_param_name.
  DATA lv_param           TYPE /scwm/de_param_name.
  DATA lv_param_structure TYPE tabname.
  DATA lv_index           TYPE i.   "#EC NEEDED

  FIELD-SYMBOLS: <ls> TYPE ANY,
                 <lv> TYPE ANY.

  notify_bell_signal = /scwm/cl_rf_bll_srvc=>get_bell_signal( ).

* 1. GET INFORMATION FROM APPLICATION

* Get screen parameters
  lt_param = /scwm/cl_rf_bll_srvc=>get_screen_param( ).

* Screen elements: menus, message texts
  /scwm/s_rf_screlm = /scwm/cl_rf_bll_srvc=>get_screlm( ).
* Screen elements for Pick by Voice
  /scwm/s_rf_screlm_pbv = /scwm/cl_rf_bll_srvc=>get_screlm_pbv( ).

* Application data
  lt_data      = /scwm/cl_rf_bll_srvc=>get_data( ).
* Current line of table to be displayed
  lv_tabline   = /scwm/cl_rf_bll_srvc=>get_line( ).
* Verification profile
  lt_verif_prf = /scwm/cl_rf_bll_srvc=>get_valid_prf( ).
* Disable all (not checked already) elements of verification profile:
* only elements existing on the screen will be enabled
  ls_verif_prf-flg_disable = /scmb/cl_c=>boole_true.
  MODIFY lt_verif_prf FROM ls_verif_prf TRANSPORTING flg_disable
         WHERE flg_disable = /scmb/cl_c=>boole_false AND
               valval_fldname IS NOT INITIAL.

* Change screen attributes according to application settings
  LOOP AT SCREEN.
    lv_attrib_req = /scwm/cl_rf_bll_srvc=>get_screlm_req_attrib_from_bll(
                       iv_screlm_name = screen-name
                       iv_index       = lv_tabline ).
    lv_attrib_inv = /scwm/cl_rf_bll_srvc=>get_screlm_inv_attrib_from_bll(
                       iv_screlm_name = screen-name
                       iv_index       = lv_tabline ).
    lv_attrib_inp = /scwm/cl_rf_bll_srvc=>get_screlm_inp_attrib_from_bll(
                       iv_screlm_name = screen-name
                       iv_index       = lv_tabline ).
*   'Invisible' attribute
    IF lv_attrib_inv IS NOT INITIAL.
      screen-invisible = lv_attrib_inv.
      IF lv_attrib_inv = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*       Field invisible -> no input & no required
        screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    CHECK lv_attrib_inv <> /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*   'Input' attribute
    IF lv_attrib_inp IS NOT INITIAL.
      screen-input = lv_attrib_inp.
      IF lv_attrib_inp = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*       Input field -> visible
        screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    CHECK lv_attrib_inp <> /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
*   'Required' attribute
    IF lv_attrib_req IS NOT INITIAL.
      screen-required = lv_attrib_req.
      IF lv_attrib_req = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
*       Required field -> visible and input
        screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
        screen-input     = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

* Ensure correspondence of <gt_scr> & <gs_scr>
* Put table parameter at the end of the parameters
  LOOP AT lt_param INTO lv_param.
    IF /scwm/cl_rf_bll_srvc=>get_param_tabletype( lv_param )
            IS NOT INITIAL.
      DELETE lt_param.
      APPEND lv_param TO lt_param.
      EXIT.
    ENDIF.
  ENDLOOP.

* Loop by definition of parameters-structures
  LOOP AT lt_param INTO lv_param.
*   Read data corresponding to parameter
    READ TABLE lt_data INTO ls_data
         WITH KEY kind = abap_func_changing
                  name = lv_param.
*   Assign reference to screen structure (TABLES:...)
    lv_param_structure = /scwm/cl_rf_bll_srvc=>get_param_structure(
                             lv_param ).
    ASSIGN (lv_param_structure) TO <gs_scr>.
    IF sy-subrc = 0.
      IF /scwm/cl_rf_bll_srvc=>get_param_tabletype( lv_param )
              IS INITIAL.
*       Structure is visible on the screen->
*       assign reference to application-value
        ASSIGN ls_data-value->* TO <ls>.
*       Pass application value to the screen element
        <gs_scr> = <ls>.
      ELSEIF lv_tabline = 0.
        ASSIGN ls_data-value->* TO <gt_scr>.
        IF sy-subrc = 0.
          DESCRIBE TABLE <gt_scr> LINES lv_lines.
          IF lv_lines = 0.
            PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGDN'.
            PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGUP'.
          ENDIF.
        ENDIF.
      ELSEIF lv_tabline > 0.
        ASSIGN ls_data-value->* TO <gt_scr>.
        IF sy-subrc = 0.
*         Assign reference to the screen structure, corresponding to the table
*         OK, structure of corresponding table is visible in the screen
*         (top includes TABLES: <structure_of_table>)
          DESCRIBE TABLE <gt_scr> LINES lv_lines.
          IF lv_lines > 0 AND iv_flg_loop = /scmb/cl_c=>boole_false.
*           Screen w/o step-loop -> read current line into
*           the structure of the screen
            READ TABLE <gt_scr> INTO <gs_scr> INDEX lv_tabline.
            CHECK sy-subrc = 0.
*           Enable/disable pushbuttons PGUP/PGDN
            IF lv_lines = lv_tabline.
*             Last line -> disable PGDN
              PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGDN'.
            ENDIF.
            IF lv_tabline = 1.
*             First line -> disable PGDN
              PERFORM deactivate USING '/SCWM/S_RF_SCRELM-PGUP'.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

* 2. SET SCREEN ELEMENTS ATTRIBUTES
* Process special screen elements
  "Get cloud system information
  DATA(lv_cloud_system) = CAST /scwm/if_tm_global_info( /scwm/cl_tm_factory=>get_service( /scwm/cl_tm_factory=>sc_globals ) )->is_s4h_cloud( ).

  LOOP AT SCREEN.
    IF screen-value_help = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      screen-value_help = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
      MODIFY SCREEN.
    ENDIF.
    CASE  screen-group3.
      WHEN /scwm/cl_rf_dynpro_srvc=>c_group3_deact_empty.
*       Deactivate if null
        ASSIGN (screen-name) TO <lv>.
        IF <lv> IS INITIAL.
          PERFORM set_on_invis_attrib.
        ENDIF.
      WHEN /scwm/cl_rf_dynpro_srvc=>c_group3_verif.
*       Set suitible element attribites for the verification field
        SPLIT screen-name AT '-' INTO lv_tabname lv_fldname.
*       Check: field defined in verification ptofile
        lv_param_name = /scwm/cl_rf_bll_srvc=>get_screen_param_by_structure(
                             lv_tabname ).

        READ TABLE lt_verif_prf INTO ls_verif_prf
             WITH KEY param_name     = lv_param_name
                      valinp_fldname = lv_fldname ##WARN_OK.
        lv_index = sy-tabix.
        IF sy-subrc = 0.
*         Yes
          IF ls_verif_prf-flg_disable = /scwm/cl_rf_bll_srvc=>c_verif_checked.
*             Field already checked
            PERFORM set_off_input_attrib.
          ELSEIF screen-invisible = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
*           Not checked & not disabled from BLL ->
*           set off indicator: Field not painted on the screen
            ls_verif_prf-flg_disable = /scmb/cl_c=>boole_false.
            MODIFY lt_verif_prf FROM ls_verif_prf INDEX sy-tabix.
          ENDIF.
        ELSE.
*         No
          PERFORM set_on_invis_attrib.
        ENDIF.
    ENDCASE.
    IF lv_cloud_system = abap_true.
      SPLIT screen-name AT '-' INTO lv_tabname lv_fldname.
      IF /scwm/cl_rf_dynpro_srvc=>check_field_is_not_in_cloud( lv_fldname ) = abap_true.
        PERFORM set_on_invis_attrib.
      ENDIF.
    ENDIF.

    IF screen-name = '/SCWM/S_RF_SCRELM-REASON_CODE' AND
       /scwm/cl_rf_bll_srvc=>get_flg_shortcut( ) =
           /scmb/cl_c=>boole_true.
      PERFORM set_on_invis_attrib.
    ENDIF.
  ENDLOOP.

* Pass verification profile to the program
  /scwm/cl_rf_bll_srvc=>set_valid_prf( lt_verif_prf ).

* 3. POSITION CURSOR

* Shortcut opened?
  IF /scwm/cl_rf_bll_srvc=>get_flg_shortcut( ) =
            /scmb/cl_c=>boole_true.
*   Indicator: cursor on shortcut
    lv_flg = /scmb/cl_c=>boole_true.
*   If shortcut is set via LIST we postion on the shortcut field
    IF /scwm/s_rf_screlm-shortcut IS NOT INITIAL.
      SET CURSOR FIELD '/SCWM/S_RF_SCRELM-SHORTCUT'.
      EXIT.
    ENDIF.
*   If cursor on the previous step was on the last field ->
*   go to shortcut (some not required field can be empty)
    IF /scwm/cl_rf_bll_srvc=>get_field_required( ) <>
          '****'.
*     Else -> all input fields filled -> go to shortcut
      LOOP AT SCREEN.
        CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
              screen-name(20) <> '/SCWM/S_RF_SCRELM-PG'.
        ASSIGN (screen-name) TO <lv>.
        CHECK <lv> IS INITIAL.
*       Initial input field -> continue cursor navigation
        lv_flg = /scmb/cl_c=>boole_false.
        EXIT.
      ENDLOOP.
    ENDIF.
  ENDIF.

* Fix required fields and make them temporary free
* in order not to receive screen errors
  LOOP AT SCREEN.
    IF screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
      screen-required = /scwm/cl_rf_dynpro_srvc=>c_attrib_off.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  CHECK lv_flg = /scmb/cl_c=>boole_false.

  IF /scwm/cl_rf_bll_srvc=>get_flg_jump_shortcut( ) = /scmb/cl_c=>boole_false.
* Try to set cursor on verification field

* Set cursor on the input field determined by application

* Get field determined by application
    lv_field_appl = /scwm/cl_rf_bll_srvc=>get_field( ).
    IF lv_field_appl IS NOT INITIAL.
      CHECK /scwm/cl_rf_bll_srvc=>get_flg_shortcut( ) =
                   /scmb/cl_c=>boole_false OR
            lv_field_appl <> '/SCWM/S_RF_SCRELM-SHORTCUT'.
*   If defined, find it
      LOOP AT SCREEN.
*     This field?
        CHECK screen-name = lv_field_appl.
*     Input field?
        IF screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
          PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
          EXIT.
        ENDIF.
        EXIT.
      ENDLOOP.

*     screen contains required fields?
      LOOP AT SCREEN.
        IF screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
           screen-name(20) <> '/SCWM/S_RF_SCRELM-PG'.
          ASSIGN (screen-name) TO <lv>.
          IF <lv> IS INITIAL.
            IF screen-group1 IS NOT INITIAL.
              /scwm/cl_rf_bll_srvc=>set_flg_input_required( screen-name ).
              EXIT.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

* Cursor was not set?
    CHECK lv_flg_cursor = /scmb/cl_c=>boole_false.

* Check if exists verification element not checked yet
    READ TABLE lt_verif_prf TRANSPORTING NO FIELDS
         WITH KEY flg_disable = /scmb/cl_c=>boole_false.
    IF sy-subrc = 0.
*   Yes: find the first one
      LOOP AT SCREEN.
*     Verification element?
        CHECK screen-group3 = /scwm/cl_rf_dynpro_srvc=>c_group3_verif.
*     Opened for input?
        CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
        ASSIGN (screen-name) TO <lv>.
        CHECK <lv> IS INITIAL.
        PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
        EXIT.
      ENDLOOP.
    ENDIF.

* Cursor was not set?
    CHECK lv_flg_cursor = /scmb/cl_c=>boole_false.

* Get field determined by screen navigation
    lv_field = /scwm/cl_rf_bll_srvc=>get_field_required( ).

    IF lv_field IS NOT INITIAL.
      LOOP AT SCREEN.
        CHECK screen-name = lv_field.
        IF screen-group1 = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
*       Set required flag
          /scwm/cl_rf_bll_srvc=>set_flg_input_required( lv_field ).
        ENDIF.
        PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
        EXIT.
      ENDLOOP.
    ELSE.
      LOOP AT SCREEN.
        IF screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
           screen-name(20) <> '/SCWM/S_RF_SCRELM-PG'.
          ASSIGN (screen-name) TO <lv>.
          IF <lv> IS INITIAL.
            IF screen-group1 IS INITIAL.
              /scwm/cl_rf_bll_srvc=>set_flg_input_possible( screen-name ).
            ELSE.
              /scwm/cl_rf_bll_srvc=>set_flg_input_required( screen-name ).
            ENDIF.
            PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
            EXIT.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

*   screen contains required fields?
    LOOP AT SCREEN.
      IF screen-input    = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
          screen-name(20) <> '/SCWM/S_RF_SCRELM-PG'.
        ASSIGN (screen-name) TO <lv>.
        IF <lv> IS INITIAL.
          IF screen-group1 IS NOT INITIAL.
            /scwm/cl_rf_bll_srvc=>set_flg_input_required( screen-name ).
            EXIT.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.

* Cursor was not set?
    CHECK lv_flg_cursor = /scmb/cl_c=>boole_false.

    LOOP AT SCREEN.
      IF lv_flg = /scmb/cl_c=>boole_true                      AND
         screen-input  = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
         screen-output = /scwm/cl_rf_dynpro_srvc=>c_attrib_on AND
         screen-name <> '/SCWM/S_RF_SCRELM-PGUP'              AND
         screen-name <> '/SCWM/S_RF_SCRELM-PGDN'.
*     Is it initial?
        ASSIGN (screen-name) TO <lv>.
        CHECK <lv> IS INITIAL.
        PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
        EXIT.
      ENDIF.
      IF screen-name = lv_field.
        IF screen-group1   = /scwm/cl_rf_dynpro_srvc=>c_group1_required.
          ASSIGN (screen-name) TO <lv>.
          IF <lv> IS INITIAL.
            PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
            EXIT.
          ELSE.
            lv_flg = /scmb/cl_c=>boole_true.
          ENDIF.
        ELSE.
          lv_flg = /scmb/cl_c=>boole_true.
        ENDIF.
      ENDIF.
    ENDLOOP.

* Cursor was not set?
    CHECK lv_flg_cursor = /scmb/cl_c=>boole_false.

* Set cursor on the first initial empty field but never on PgUp/PgDn
    LOOP AT SCREEN.
*   Field opened for input?
      CHECK screen-input = /scwm/cl_rf_dynpro_srvc=>c_attrib_on.
      CHECK screen-name <> '/SCWM/S_RF_SCRELM-PGUP'.
      CHECK screen-name <> '/SCWM/S_RF_SCRELM-PGDN'.

*   Is it initial?
      ASSIGN (screen-name) TO <lv>.
      CHECK <lv> IS INITIAL.
      PERFORM set_cursor CHANGING lv_flg_cursor gv_field.
      EXIT.
    ENDLOOP.
  ELSE.
    SET CURSOR FIELD '/SCWM/S_RF_SCRELM-SHORTCUT'.
    /scwm/cl_rf_bll_srvc=>set_flg_jump_shortcut( /scmb/cl_c=>boole_false ).
  ENDIF.
ENDFORM.                    " status_sscr
