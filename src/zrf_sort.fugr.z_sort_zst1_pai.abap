FUNCTION z_sort_zst1_pai.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"----------------------------------------------------------------------
  DATA: lt_rng_idplate TYPE rseloption,
        lt_huitm       TYPE /scwm/tt_huitm_int,
        lv_lines       TYPE sy-tabix,
        lv_open_to     TYPE xfeld.

  BREAK-POINT ID zewmdevbook_336.

  "1 validation of user-input
  CLEAR: zsort-source_hu, zsort-guid_stock.
  IF zsort-idplate IS INITIAL.
    MESSAGE 'Enter a stock identification' TYPE wmegc_severity_err.
  ENDIF.
  "2 check if ID is a valid stock identification
  DATA(ls_rng_idplate) = VALUE rsdsselopt( low    = zsort-idplate
                                           sign   = wmegc_sign_inclusive
                                           option = wmegc_option_eq ).
  APPEND ls_rng_idplate TO lt_rng_idplate.

  CALL FUNCTION '/SCWM/HU_SELECT_QUAN'
    EXPORTING
      iv_lgnum   = zsort-lgnum
      ir_idplate = lt_rng_idplate
    IMPORTING
      et_huitm   = lt_huitm
    EXCEPTIONS
      OTHERS     = 99.
  DELETE lt_huitm WHERE vsi <> wmegc_physical_stock.
  TRY.
      DATA(ls_huitm) = VALUE #( lt_huitm[ idplate = zsort-idplate ] ).
    CATCH cx_sy_itab_line_not_found.
      CLEAR zsort-idplate.
      MESSAGE 'Stock Identification not found' TYPE wmegc_severity_err.
      RETURN.
  ENDTRY.
  "3 validations
  CALL FUNCTION '/SCWM/CHECK_OPEN_TO'
    EXPORTING
      iv_hu    = ls_huitm-guid_parent
      iv_lgnum = zsort-lgnum
    IMPORTING
      ev_exist = lv_open_to
    EXCEPTIONS
      OTHERS   = 99.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  IF lv_open_to IS NOT INITIAL.
    MESSAGE 'Open Task exists for pick-HU' TYPE wmegc_severity_err.
  ENDIF.
  "4 set technical fields in RF application
  zsort-source_hu  = ls_huitm-guid_parent.
  zsort-guid_stock = ls_huitm-guid_stock.

ENDFUNCTION.
