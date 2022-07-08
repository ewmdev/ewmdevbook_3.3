FUNCTION z_sort_zst2_pai.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  CHANGING
*"     REFERENCE(ZSORT) TYPE  ZRF_SORT
*"----------------------------------------------------------------------

  BREAK-POINT ID zewmdevbook_336.

  "0 stay on this screen (default)
  /scwm/cl_rf_bll_srvc=>set_prmod(
  /scwm/cl_rf_bll_srvc=>c_prmod_foreground ).
  "1 validation of user-input
  IF zsort-rfhu IS INITIAL.
    MESSAGE 'Enter Handling Unit' TYPE 'E'.
  ENDIF.
  "2 get destination hu
  go_pack->get_hu(
    EXPORTING
      iv_huident = CONV #( zsort-rfhu )
    IMPORTING
      es_huhdr   = DATA(ls_dest_hu)
    EXCEPTIONS
      OTHERS = 99 ).
  IF sy-subrc <> 0.
    CLEAR zsort-rfhu. "Scanning Error
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  IF ls_dest_hu-copst IS NOT INITIAL.
    MESSAGE 'HU is closed' TYPE 'E'.
  ENDIF.
  "3 repack item into the dest hu
  DATA(ls_quan) = VALUE /scwm/s_quan( quan = zsort-vsola
                                      unit = zsort-altme ).
  go_pack->repack_stock(
    EXPORTING
      iv_dest_hu    = ls_dest_hu-guid_hu
      iv_source_hu  = zsort-source_hu
      iv_stock_guid = zsort-guid_stock
      is_quantity   = ls_quan
    EXCEPTIONS
      OTHERS = 99 ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "4 save
  go_pack->/scwm/if_pack_bas~save(
    EXPORTING
      iv_commit = abap_true
      iv_wait   = abap_true
    EXCEPTIONS
      OTHERS = 99 ).
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    /scwm/cl_tm=>cleanup( ).
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "5 navigate to the transaction end
  /scwm/cl_rf_bll_srvc=>set_prmod(
    /scwm/cl_rf_bll_srvc=>c_prmod_background ).

ENDFUNCTION.
