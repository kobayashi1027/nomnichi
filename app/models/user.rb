class User < ActiveRecord::Base
  has_many :articles
  has_many :comments

  require "digest/sha1"

  validates_uniqueness_of :ident

  def self.current=(user)
    @current_user = user
  end

  def self.current
    @current_user
  end

  def self.authenticate(ident, password)
    user = find_by("ident = ?", ident)
    return false if user.nil?
    pass_sha = Digest::SHA1.hexdigest(user.salt + password)
    return where(["ident=? AND password=?", ident, pass_sha]).first
  end

  # Omniauth-github has these info:
  #   https://github.com/intridea/omniauth-github/blob/master/lib/omniauth/strategies/github.rb
  #
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid      = auth["uid"]

      info = auth["info"]
      user.ident      = info["nickname"]
      user.avatar_url = info["image"]
    end
  end

  def self.generate_salt
    Time.now.to_s
  end

  def self.encrypted_password(unencrypted_password, salt)
    Digest::SHA1.hexdigest(salt + unencrypted_password)
  end

  def update_with_omniauth(auth)
    update!(
      provider:   auth["provider"],
      uid:        auth["uid"],
      avatar_url: auth["info"]["image"]
    )
  end

  def is_associated?
    provider && uid
  end
end
