require 'spec_helper'

describe SportsSouth::User do

  it 'has a API_URL constant' do
    expect(SportsSouth::User::API_URL).not_to be_nil
  end

  describe '#authenticated?' do
    let(:user) { SportsSouth::User.new(username: "bob", password: "secret", customer_number: "10001", source: "ruby-gem") }

    before do
      stub_request(:post, "http://webservices.theshootingwarehouse.com/smart/users.asmx/GetEmailPrefs").
        with(:body => {"CustomerNumber"=>"10001", "Password"=>"secret", "Source"=>"ruby-gem", "UserName"=>"bob"},
          :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'sports_south rubygems.org/gems/sports_south v(0.12.2)'}).
        to_return(:status => 200, :body => %q(<string xmlns="http://webservices.theshootingwarehouse.com/smart/Users.asmx">string</string>), :headers => {})
    end

    it { expect(user.authenticated?).to be(true) }
  end

end
