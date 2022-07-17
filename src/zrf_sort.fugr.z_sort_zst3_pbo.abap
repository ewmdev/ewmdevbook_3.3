FUNCTION z_sort_zst3_pbo.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"     REFERENCE(CT_INQ_HU_LOOP) TYPE  /SCWM/TT_RF_INQ_HU_LOOP
*"----------------------------------------------------------------------
  DATA: lt_huhdr   TYPE /scwm/tt_huhdr_int,
        ls_hu_loop TYPE /scwm/s_rf_inq_hu_loop,
        lt_dstgrp  TYPE rseloption,
        lt_lgpla   TYPE rseloption.

  BREAK-POINT ID zewmdevbook_336.

  "1. Get bin of the pick hu
  go_pack->get_hu(
    EXPORTING
      iv_guid_hu = zsort-source_hu
    IMPORTING
      es_huhdr   = DATA(ls_huhdr)
    EXCEPTIONS
      OTHERS     = 99 ).
  IF sy-subrc <> 0. "technical error
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  DATA(ls_selopt) = VALUE rsdsselopt(
    low    = ls_huhdr-lgpla
    sign   = wmegc_sign_inclusive
    option = wmegc_option_eq ).
  APPEND ls_selopt TO lt_lgpla.
  ls_selopt-low = zsort-dstgrp.
  APPEND ls_selopt TO lt_dstgrp.
  "2. Get all HUs on this bin with same consol. group
  CALL FUNCTION '/SCWM/HU_SELECT_GEN'
    EXPORTING
      iv_lgnum  = zsort-lgnum
      ir_lgpla  = lt_lgpla
      ir_dstgrp = lt_dstgrp
    IMPORTING
      et_huhdr  = lt_huhdr
    EXCEPTIONS
      OTHERS    = 99.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "3. Prepare List of HU
  CLEAR ct_inq_hu_loop.
  DELETE lt_huhdr WHERE copst IS NOT INITIAL.
  LOOP AT lt_huhdr ASSIGNING FIELD-SYMBOL(<huhdr>).
    CLEAR ls_hu_loop.
    ls_hu_loop-seqno = sy-tabix.
    MOVE-CORRESPONDING <huhdr> TO ls_hu_loop.
    APPEND ls_hu_loop TO ct_inq_hu_loop.
  ENDLOOP.

  "4. Set screen elements for RF Framework
  /scwm/cl_rf_bll_srvc=>init_screen_param( ).
  /scwm/cl_rf_bll_srvc=>set_screen_param('CS_INQ_HU').
  /scwm/cl_rf_bll_srvc=>set_screen_param('CT_INQ_HU_LOOP').
  CALL METHOD /scwm/cl_rf_bll_srvc=>set_scr_tabname
    EXPORTING
      iv_scr_tabname = '/SCWM/TT_RF_INQ_HU_LOOP'.
  CALL METHOD /scwm/cl_rf_bll_srvc=>set_line
    EXPORTING
      iv_line = 1.

ENDFUNCTION.
