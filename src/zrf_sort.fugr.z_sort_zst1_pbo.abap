FUNCTION z_sort_zst1_pbo.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"----------------------------------------------------------------------
  DATA: ls_rsrc TYPE /scwm/rsrc.

  BREAK-POINT ID zewmdevbook_336.

  "1 init the work area
  CLEAR zsort.
  "get warehouse number of this resource
  CALL FUNCTION '/SCWM/RSRC_RESOURCE_MEMORY'
    EXPORTING
      iv_uname    = sy-uname
    CHANGING
      cs_rsrc     = ls_rsrc.
      zsort-lgnum = ls_rsrc-lgnum.

  "2 init packing & transaction manager
  /scwm/cl_tm=>set_lgnum( iv_lgnum = zsort-lgnum ).
  IF go_pack IS NOT BOUND.
    go_pack = NEW /scwm/cl_wm_packing( ).
  ENDIF.
  DATA(ls_pack_controle) = VALUE /scwm/s_pack_controle(
    cdstgrp_mat    = abap_true "take over cons.group
    chkpack_dstgrp = '2' "check while repack products
    processor_det  = abap_true ).
  go_pack->init(
     EXPORTING
       iv_lgnum         = zsort-lgnum
       is_pack_controle = ls_pack_controle
     EXCEPTIONS
       error            = 1
       OTHERS           = 2 ).
  IF sy-subrc <> 0.
    /scwm/cl_pack_view=>msg_error( ).
  ENDIF.

  "3 init stock-ui
  IF go_stock IS INITIAL.
    CREATE OBJECT go_stock.
  ENDIF.

ENDFUNCTION.
