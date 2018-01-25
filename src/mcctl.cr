require "./mcctl/*"
require "dbus"
require "commander"

bus = DBus::Bus.new
mconnect = bus.destination("org.mconnect")
device_manager = mconnect.object("/org/mconnect/manager").interface("org.mconnect.DeviceManager")

def err_bail(msg)
  puts msg
  exit 1
end

def expand_devid(manager, args)
  if args.size < 1
    device = manager.call("ListDevices").reply.first
    if device.is_a?(String)
      puts "Is mconnect running?"
      err_bail(device)
    end
    device.as(Array).first.as(String).split("/").last
  end
  device_prefix = "/org/mconnect/device/"
  device = args.first
  device = device_prefix + device unless device.starts_with?(device_prefix)
  device
end

cli = Commander::Command.new do |cmd|
  cmd.use = "mcctl"
  cmd.long = "mconnect control - control available mconnect devices"
  cmd.run do |options, arguments|
    puts cmd.help
  end

  cmd.commands.add do |cmd|
    cmd.use = "list"
    cmd.short = "list available devices"
    cmd.long = cmd.short
    cmd.run do |options, arguments|
      devices = device_manager.call("ListDevices").reply

      devices.each do |device|
        if device.is_a?(String)
          err_bail(device)
        end

        path = device.as(Array).first.as(String)
        device_interface = mconnect.object(path)
        device_properties = device_interface.propRetriever("org.mconnect.Device")

        padding = "\t"
        puts "#{path} =>"
        puts padding*1 + "Type: #{device_properties.get("DeviceType").as(String).capitalize}"
        puts padding*1 + "Name: #{device_properties.get("Name").as(String)}"
        puts padding*1 + "Identifier: #{device_properties.get("Id").as(String)}"
        puts padding*1 + "Address: #{device_properties.get("Address").as(String)}"
        puts padding*1 + "Connected: #{device_properties.get("IsConnected").as(Bool)}"
        puts padding*1 + "Active: #{device_properties.get("IsActive").as(Bool)}"
        puts padding*1 + "Paired: #{device_properties.get("IsPaired").as(Bool)}"
      end
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "get-battery [device]"
    cmd.short = "get the current battery percentage"
    cmd.long = cmd.short + ", defaults to the first device if none given"
    cmd.run do |options, arguments|
      device = expand_devid(device_manager, arguments)
      device_interface = mconnect.object(device)
      device_battery = device_interface.propRetriever("org.mconnect.Device.Battery")
      puts device_battery.get("Level").as(Int)
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "is-charging [device]"
    cmd.short = "check whether the device is being charged"
    cmd.long = cmd.short + ", defaults to the first device if none given"
    cmd.run do |options, arguments|
      device = expand_devid(device_manager, arguments)
      device_interface = mconnect.object(device)
      device_battery = device_interface.propRetriever("org.mconnect.Device.Battery")
      puts device_battery.get("Charging").as(Bool)
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "share-text <text> [device]"
    cmd.short = "share text to the device"
    cmd.long = cmd.short + ", <device> defaults to the first device if none given"
    cmd.run do |options, arguments|
      if arguments.size < 1
        err_bail("Missing arguments")
      end
      text = arguments.shift
      device = expand_devid(device_manager, arguments)
      device_interface = mconnect.object(device)
      device_share = device_interface.interface("org.mconnect.Device.Share")
      device_share.call("ShareText", [text]).reply
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "share-url <url> [device]"
    cmd.short = "share url to the device"
    cmd.long = cmd.short + ", <device> defaults to the first device if none given"
    cmd.run do |options, arguments|
      if arguments.size < 1
        err_bail("Missing arguments")
      end
      url = arguments.shift
      device = expand_devid(device_manager, arguments)
      device_interface = mconnect.object(device)
      device_share = device_interface.interface("org.mconnect.Device.Share")
      device_share.call("ShareUrl", [url]).reply
    end
  end

  cmd.commands.add do |cmd|
    cmd.use = "share-file <file> [device]"
    cmd.short = "share a file to the device"
    cmd.long = cmd.short + ", <device> defaults to the first device if none given"
    cmd.run do |options, arguments|
      if arguments.size < 1
        err_bail("Missing arguments")
      end
      file = arguments.shift
      device = expand_devid(device_manager, arguments)
      device_interface = mconnect.object(device)
      device_share = device_interface.interface("org.mconnect.Device.Share")
      device_share.call("ShareFile", [File.expand_path(file)]).reply
    end
  end
end

Commander.run(cli, ARGV)
