require_relative 'spec_helper'

describe DpnSync do
  it 'responds with a welcome message' do
    get '/'
    expect(last_response.body).to include 'Welcome to the Sinatra Template!'
  end
end
