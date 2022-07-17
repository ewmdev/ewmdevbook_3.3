FUNCTION z_sort_zst2_exceptions.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"----------------------------------------------------------------------

  CONSTANTS: lc_buscon(3)   VALUE '9PA',
             lc_execstep(2) VALUE '18'.

  DATA: ls_exccode TYPE /scwm/s_iexccode,
        lv_fcode   type /scwm/de_fcode.

  BREAK-POINT ID zewmdevbook_336.

  "1. Checks & initializations
  IF zsort-source_hu IS INITIAL.
    RETURN.
  ENDIF.
  "Get shortcut
  DATA(lv_shortcut) = /scwm/cl_rf_bll_srvc=>get_shortcut( ).
  "Create instance of Exception object
  DATA(lo_excep) = /scwm/cl_exception_appl=>create_exception_object( ).
  "2. Verify exception code entered by the user
  ls_exccode-exccode = lv_shortcut.
  /scwm/cl_exception_appl=>verify_exception_code(
    EXPORTING
      is_appl_item_data = zsort
      iv_lgnum          = zsort-lgnum
      iv_buscon         = lc_buscon
      iv_execstep       = lc_execstep
      ip_excep          = lo_excep
    CHANGING
      cs_exccode        = ls_exccode ).
  "Exception code is not maintained in customizing
  IF ls_exccode-valid <> abap_true.
    "Exception code is not allowed
    MESSAGE e003(/scwm/exception)
    WITH ls_exccode-exccode.
    RETURN.
  ENDIF.
  "3. Handle exceptions
  CASE ls_exccode-iprcode.
    WHEN wmegc_iprcode_list.
      "4. Handle exception code ”list”
      CALL FUNCTION '/SCWM/RSRC_EXCEPTION_LIST_FILL'
        EXPORTING
          iv_lgnum     = zsort-lgnum
          iv_buscon    = lc_buscon
          iv_exec_step = lc_execstep.
      lv_fcode = wmegc_iprcode_list.
      /scwm/cl_rf_bll_srvc=>set_fcode( lv_fcode ).
      /scwm/cl_rf_bll_srvc=>set_prmod(
        /scwm/cl_rf_bll_srvc=>c_prmod_background ).
      CALL METHOD /scwm/cl_rf_bll_srvc=>set_field
        EXPORTING
          iv_field = '/SCWM/S_RF_SCRELM-SHORTCUT'.
    WHEN wmegc_iprcode_skfd.
      "5. Handle exception code ”Skip verification field”
      zsort-matnr_verif = zsort-matnr. "verify the product
      /scwm/cl_rf_bll_srvc=>set_prmod(
        /scwm/cl_rf_bll_srvc=>c_prmod_foreground ).
    WHEN OTHERS.
      "Exception code is not allowed
      MESSAGE e003(/scwm/exception) WITH lv_shortcut.
  ENDCASE.
  /scwm/cl_rf_bll_srvc=>clear_shortcut( ).

ENDFUNCTION.
