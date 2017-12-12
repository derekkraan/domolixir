# Domolixir

Domolixir is a pure-Elixir solution for your smart home. It currently supports (part of) ZWave, with plans to support Philips Hue in the future. 

This project is a WIP, but if you want, you can already use it to see how things are going.

Domolixir current consists of three parts:

web - a phoenix project that is the user interface to Domolixir.
domo - a library to interface with various domotica hardware (currently supports ZWave).
fw - a nerves project to get web and domo running on a Raspberry PI.

## Running Domolixir on a computer
```bash
git clone https://github.com/derekkraan/domolixir domolixir
cd domolixir/apps/web
mix deps.get
mix phx.server
# or: iex -S mix phx.server
```

## Burning this to an SD card for use on an RPI
```bash
git clone https://github.com/derekkraan/domolixir domolixir
cd domolixir/apps/fw
export MIX_TARGET=rpi0 # rpi0 is for the Raspberry Pi Zero (W) ... adjust for the actual rpi you have
export MIX_ENV=prod
mix deps.get
mix firmware
# insert SD card into computer
mix firmware.burn
```
