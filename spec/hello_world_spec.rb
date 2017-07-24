require File.expand_path '../spec_helper.rb', __FILE__

describe "The application" do

  it "renders Hello World" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to include('Hello World')
  end

end
