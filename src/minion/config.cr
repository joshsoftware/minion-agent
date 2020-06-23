require "json"

module Minion
  struct Config
    property server_id
    property server_name
    property group_id
    property group_key
    property streamserver_ip
    property streamserver_port

    def initialize(filename)
      json = JSON.parse(File.read(filename))

      @server_id         = json["server_id"]
      @server_name       = json["server_name"]
      @group_id          = json["group_id"]
      @group_key         = json["group_key"]
      @streamserver_ip   = json["streamserver_ip"]
      @streamserver_port = json["streamserver_port"]
    end
  end
end
