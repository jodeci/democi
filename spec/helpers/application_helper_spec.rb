# frozen_string_literal: true
require "rails_helper"
describe ApplicationHelper, type: :helper do
  it { expect(helper.demo).to eq "hello, world!" }
end
