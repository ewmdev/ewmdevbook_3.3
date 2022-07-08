FUNCTION-POOL zrf_sort.                     "MESSAGE-ID ..

* INCLUDE LZRF_SORTD...                      " Local class definition

TYPE-POOLS: wmegc.
DATA: go_pack  TYPE REF TO /scwm/cl_wm_packing,
      go_stock TYPE REF TO /scwm/cl_ui_stock_fields.
