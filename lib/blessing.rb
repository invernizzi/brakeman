require 'digest/md5'


module Brakeman::Blessing

  @@WHOLE_LINE_COMMENTS = {:ruby => /^\s*#(.+)$/,
    :haml => /<%#([^%>]+)%>$/,
    :erb => /<%#([^%>]+)%>/}
  @@HASH_IN_COMMENT = /(?:^|\W)([a-z0-9]{32})(?:\W|$)/

    @@blessings = Hash.new

  def self.is_blessed?(result)
    hash = self.hash_result result
    @@blessings[hash]
  end

  def self.hash_result(result)
    Digest::MD5.hexdigest("#{result.class}\n#{result.code.to_s}\n#{result.check.sub /^Brakeman::/, ''}")
  end

  def self.add_blessing(blessing_hash)
    @@blessings[blessing_hash] = true
  end

  def self.parse_string_for_blessings string, language=:ruby
    comments = string.scan @@WHOLE_LINE_COMMENTS[language]
    comments.each do |comment|
      comment[0].scan(@@HASH_IN_COMMENT) do |blessing_hash|
        Brakeman::Blessing.add_blessing blessing_hash[0].strip
      end
    end
  end

end
