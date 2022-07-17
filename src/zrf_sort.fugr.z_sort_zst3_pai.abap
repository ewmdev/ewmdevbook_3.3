FUNCTION z_sort_zst3_pai.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"     REFERENCE(CT_INQ_HU_LOOP) TYPE  /SCWM/TT_RF_INQ_HU_LOOP
*"     REFERENCE(CS_INQ_HU) TYPE  /SCWM/S_RF_INQ_HU
*"----------------------------------------------------------------------

  BREAK-POINT ID zewmdevbook_336.

  "1. Validation of user-input
  DATA(ls_inq_hu) = VALUE /scwm/s_rf_inq_hu_loop(
    ct_inq_hu_loop[ cs_inq_hu-selno ] ).
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e108(/scwm/rf_en) WITH cs_inq_hu-selno.
  ENDIF.
  "2. Forward user-selection to screen 2
  zsort-rfhu = ls_inq_hu-huident.
  /scwm/cl_rf_bll_srvc=>set_screen_param('ZSORT').

ENDFUNCTION.
