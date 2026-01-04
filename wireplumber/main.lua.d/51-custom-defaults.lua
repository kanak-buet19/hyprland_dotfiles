rule = {
  matches = {
    {
      { "node.name", "matches", "alsa_output.pci-0000_*_00.1.analog-stereo" },
    },
  },
  apply_properties = {
    ["audio.volume"] = 1.0,
  },
}

table.insert(alsa_monitor.rules, rule)
