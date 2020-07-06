module Minion
  class Agent
    class UpgradeData
      include JSON::Serializable
      include JSON::Serializable::Unmapped

      @[JSON::Field(key: "latest_version")]
      property latest_version : String

      @[JSON::Field(key: "md5")]
      property md5 : String

      @[JSON::Field(key: "download_url")]
      property download_url : String
    end
  end
end
