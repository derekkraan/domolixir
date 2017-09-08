defmodule ZStick.Constants do
  defmacro __using__(_) do
    quote do
      @func_id_zw_get_version 0x15
      @func_id_zw_memory_get_id 0x20
      @func_id_zw_get_controller_capabilities 0x05
      @func_id_serial_api_get_capabilities 0x07
      @func_id_zw_get_suc_node_id 0x56
      @func_id_zw_set_learn_mode 0x50

      @func_id_zw_get_random 0x1c
      @func_id_zw_get_controller_capabilities 0x05

      @request 0x00
      @response 0x01

      @sof 0x01
      @ack 0x06
      @nak 0x15
      @can 0x18
    end
  end
end
