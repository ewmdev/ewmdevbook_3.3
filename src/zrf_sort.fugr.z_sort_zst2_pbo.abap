FUNCTION z_sort_zst2_pbo.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"----------------------------------------------------------------------

  BREAK-POINT ID zewmdevbook_336.

  "1. Get item details
  go_pack->get_hu_item(
    EXPORTING
      iv_guid_hu    = zsort-source_hu
      iv_guid_stock = zsort-guid_stock
    IMPORTING
      es_huitm = DATA(ls_huitm)
    EXCEPTIONS
      OTHERS = 99 ).
  IF sy-subrc <> 0. "technical error
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "2. Set application screen fields
  zsort-dstgrp = ls_huitm-dstgrp.
  zsort-vsola  = ls_huitm-quana.
  zsort-altme  = ls_huitm-altme.
  CALL METHOD go_stock->get_matkey_by_id
    EXPORTING
      iv_matid = ls_huitm-matid
    IMPORTING
      ev_matnr = zsort-matnr
      ev_maktx = zsort-maktx.

ENDFUNCTION.
