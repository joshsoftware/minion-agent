require "yaml"

module Minion
  class Config
    include YAML::Serializable
    include YAML::Serializable::Unmapped

    @[YAML::Field(key: "server_id")]
    property server_id         : String

    @[YAML::Field(key: "server_name")]
    property server_name       : String

    @[YAML::Field(key: "group_id")]
    property group_id          : String

    @[YAML::Field(key: "group_key")]
    property group_key         : String

    @[YAML::Field(key: "streamserver_host")]
    property streamserver_host : String

    @[YAML::Field(key: "streamserver_port")]
    property streamserver_port : Int32

    @[YAML::Field(key: "tail_logs")]
    property tail_logs : Array(String)
  end
end
