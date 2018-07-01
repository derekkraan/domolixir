defmodule ZWaveDiscoverBench do
  use Benchfella

  setup_all do
    ZWave.Discover.start_link
  end

  bench "discovering zsticks" do
    ZWave.Discover.discover
  end
end
