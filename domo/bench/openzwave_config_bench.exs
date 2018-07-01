defmodule OpenZWaveConfigBench do
  use Benchfella

  bench "reading device_classes.xml" do
    OpenZWaveConfig.command_classes(161, 2)
  end
end
