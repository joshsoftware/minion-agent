require "yaml"

module Minion
  @[YAML::Serializable::Options(emit_nulls: true)]
  class Config
    include YAML::Serializable
    include YAML::Serializable::Unmapped

    @[YAML::Field(key: "upgrade")]
    property upgrade : String = "http://getminion.io/api/v1/minion"

    @[YAML::Field(key: "server_id", emit_null: true)]
    property server_id : String = ""

    @[YAML::Field(key: "server_name", emit_null: true)]
    property server_name : String = ""

    @[YAML::Field(key: "group_id", emit_null: true)]
    property group_id : String = ""

    @[YAML::Field(key: "group_key", emit_null: true)]
    property group_key : String = ""

    @[YAML::Field(key: "streamserver_host", emit_null: true)]
    property streamserver_host : String = ""

    @[YAML::Field(key: "streamserver_port")]
    property streamserver_port : Int32 = 47990

    @[YAML::Field(key: "tail_logs", emit_null: true)]
    property tail_logs : Array(Minion::Config::TailConfig)?

    @[YAML::Field(key: "telemetries", emit_null: true)]
    property telemetries : Array(Minion::Config::CustomTelemetry)?

    @[YAML::Serializable::Options(emit_nulls: true)]
    class TailConfig
      include YAML::Serializable
      include YAML::Serializable::Unmapped

      @[YAML::Field(key: "service")]
      property service : String

      @[YAML::Field(key: "file")]
      property file : String
    end

    @[YAML::Serializable::Options(emit_nulls: true)]
    class CustomTelemetry
      include YAML::Serializable
      include YAML::Serializable::Unmapped

      @[YAML::Field(key: "name")]
      property name : String

      @[YAML::Field(key: "command")]
      property command : String

      @[YAML::Field(key: "args")]
      property args : Array(String)

      @[YAML::Field(key: "interval")]
      property interval : Int32
    end
  end
end
