defmodule OpenZWaveConfig do
  def command_class(generic, specific) do
    {:ok, state, ""} = Path.join(:code.priv_dir(:domo), "open-zwave/device_classes.xml")
    |> :xmerl_sax_parser.file(event_fun: &xml_event/3)
    find_command_class(state.specifics, int2hex(generic), int2hex(specific))
                 # |> File.read
    # generic_hex = int2hex(generic)
    # specific_hex = int2hex(specific)
    # {doc, _} = xml
          # |> :binary.bin_to_list
          # |> :xmerl_scan.string()
    # :xmerl_xpath.string('/DeviceClasses/Generic[@key="#{generic_hex}"]/Specific[@key="#{specific_hex}"]@command_classes', doc)
    # state # parse config/device_classes.xml to get command classes
  end

  defp find_command_class([], _gen, _spe), do: nil
  defp find_command_class([specific | specifics], gen, spe) do
    if specific.generic_key == gen && specific.specific_key == spe do
      specific.command_classes
    else
      find_command_class(specifics, gen, spe)
    end
  end

  defp int2hex(int) do
    "0x#{Integer.to_string(int, 16) |> String.pad_leading(2, "0")}"
  end

  @empty_attrs %{command_classes: [], label: "", key: ""}

  def xml_event(:startDocument, _location, _state), do: %{current_generic: nil, specifics: []}

  def xml_event({:startElement, _uri, 'Generic', _qual_name, attributes}, _location, state) do
    %{state | current_generic: Map.merge(@empty_attrs, attrs_to_map(attributes))}
  end

  def xml_event({:startElement, _uri, 'Specific', _qual_name, attributes}, _location, state) do
    specific_attrs = Map.merge(@empty_attrs, attrs_to_map(attributes))
    specific = %{generic_key: state.current_generic.key, specific_key: specific_attrs.key, generic_label: state.current_generic.label, label: specific_attrs.label, command_classes: (specific_attrs.command_classes || []) ++ (state.current_generic.command_classes || [])}
    %{state | specifics: [specific | state.specifics]}
  end

  def xml_event(_event, _location, state) do
    state
  end

  def attrs_to_map(attrs, map\\%{})
  def attrs_to_map([], map), do: map
  def attrs_to_map([{_, _, name = 'command_classes', command_classes} | attrs], map) do
    attrs
    |> attrs_to_map(Map.put(map, name |> to_string() |> String.to_atom(), command_classes |> parse_command_classes()))
  end
  def attrs_to_map([{_, _, name, val} | attrs], map) do
    attrs
    |> attrs_to_map(Map.put(map, name |> to_string() |> String.to_atom(), val |> to_string()))
  end

  def parse_command_classes(charlist), do: parse_command_classes(charlist |> to_string() |> String.split(","), [])
  def parse_command_classes([], result), do: result
  def parse_command_classes(["0x" <> command_class | command_classes], result) do
    parse_command_classes(command_classes, [String.to_integer(command_class, 16) | result])
  end
end
