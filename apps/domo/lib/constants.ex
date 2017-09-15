defmodule ZStick.Constants do
  defmacro __using__(_) do
    quote do
      @func_id_zw_get_version 0x15
      @func_id_zw_memory_get_id 0x20
      @func_id_zw_get_controller_capabilities 0x05
      @func_id_serial_api_get_capabilities 0x07
      @func_id_zw_get_suc_node_id 0x56
      @func_id_zw_set_learn_mode 0x50
      @func_id_zw_enable_suc 0x52
      @func_id_zw_set_suc_node_id 0x54

      @func_id_zw_get_random 0x1c

      @func_id_zw_request_node_neighbor_update 0x48

      @func_id_zw_request_node_info 0x60

      @func_id_zw_request_network_update 0x53

      @func_id_serial_api_get_init_data 0x02
      @func_id_serial_api_appl_node_information 0x03

      @func_id_zw_get_node_protocol_info 0x41

      @request 0x00
      @response 0x01

      @suc_func_nodeid_server 0x01

      @num_node_bitfield_bytes 29 # 29 = 232 / 8
      @max_num_nodes 232

      @sof 0x01
      @ack 0x06
      @nak 0x15
      @can 0x18
    end
  end
end
