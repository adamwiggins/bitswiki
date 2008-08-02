RAILS_GEM_VERSION = '2.0.2'

require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.action_controller.session = {
    :session_key => '_bitswiki_session',
    :secret      => '62d9b151ee879e88088d2e91ab0a205918beaa2fff2ca268b8ddc7b61478a9c03723059d96031b64d9ae481357f25a1966afa0517d8a76604d636fab6b7c329d'
  }
end

Logo = "bitswiki.png"

ExternalLinks = {
  # "link text" => "url"
}

WikiOptions = {
  :allow_anonymous_read   => true,
  :allow_anonymous_write  => true,
  :access_denied_url       => '/login'
}
