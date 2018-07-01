defmodule OpenZWaveConfig do
  def get_information(generic, specific) do
    {:ok, state, ""} =
      Path.join(:code.priv_dir(:domo), "open-zwave/device_classes.xml")
      |> :xmerl_sax_parser.file(event_fun: &OpenZWaveDeviceClassesSaxParser.xml_event/3)

    find_specific(state.specifics, generic |> int2hex(), specific |> int2hex())
  end

  def command_classes(generic, specific) do
    get_information(generic, specific).command_classes
  end

  @empty_attrs %{command_classes: [], label: "", key: ""}

  defp find_specific([], _gen, _spe), do: @empty_attrs

  defp find_specific([specific = %{generic_key: gen, specific_key: spe} | specifics], gen, spe),
    do: specific

  defp find_specific([_specific | specifics], gen, spe), do: find_specific(specifics, gen, spe)

  defp int2hex(int) do
    "0x#{Integer.to_string(int, 16) |> String.pad_leading(2, "0")}"
  end
end

defmodule OpenZWaveDeviceClassesSaxParser do
  @empty_attrs %{command_classes: [], label: "", key: ""}

  def xml_event(:startDocument, _location, _state), do: %{current_generic: nil, specifics: []}

  def xml_event({:startElement, _uri, 'Generic', _qual_name, attributes}, _location, state) do
    %{state | current_generic: Map.merge(@empty_attrs, attrs_to_map(attributes))}
  end

  def xml_event({:startElement, _uri, 'Specific', _qual_name, attributes}, _location, state) do
    specific_attrs = Map.merge(@empty_attrs, attrs_to_map(attributes))

    specific = %{
      generic_key: state.current_generic.key,
      specific_key: specific_attrs.key,
      generic_label: state.current_generic.label,
      label: specific_attrs.label,
      command_classes:
        (specific_attrs.command_classes || []) ++ (state.current_generic.command_classes || [])
    }

    %{state | specifics: [specific | state.specifics]}
  end

  def xml_event(_event, _location, state) do
    state
  end

  defp attrs_to_map(attrs, map \\ %{})
  defp attrs_to_map([], map), do: map

  defp attrs_to_map([{_, _, name = 'command_classes', command_classes} | attrs], map) do
    attrs
    |> attrs_to_map(
      Map.put(
        map,
        name |> to_string() |> String.to_atom(),
        command_classes |> parse_command_classes()
      )
    )
  end

  defp attrs_to_map([{_, _, name, val} | attrs], map) do
    attrs
    |> attrs_to_map(Map.put(map, name |> to_string() |> String.to_atom(), val |> to_string()))
  end

  defp parse_command_classes(charlist),
    do: parse_command_classes(charlist |> to_string() |> String.split(","), [])

  defp parse_command_classes([], result), do: result

  defp parse_command_classes(["0x" <> command_class | command_classes], result) do
    parse_command_classes(command_classes, [String.to_integer(command_class, 16) | result])
  end
end
