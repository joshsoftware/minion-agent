module Minion
  class Agent
    class UpgradeData
      include JSON::Serializable
      include JSON::Serializable::Unmapped

      @[JSON::Field(key: "latest_version")]
      property latest_version

      @[JSON::Field(key: "sha256")]
      property sha256

      @[JSON::Field(key: "download_url")]
      property download_url

    end
  end
end
