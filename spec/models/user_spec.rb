require 'spec_helper'
require 'cancan/matchers'

describe User do

  context "user" do
    let(:user) do
      FactoryGirl.create(:user)
    end
  
    it "should have a username" do
      user.username.should_not == ""
    end

    it "should not be a subscriber" do
      user.subscriber?.should be_false
    end

    context "with a subscriber parent" do
      let(:ability){ Ability.new(user) }
      before(:each) do
        sub = FactoryGirl.create(:subscription)
        sub.user.children << user
      end
      it "has a subscription" do
        user.subscriber?.should be_true
      end
      it "can't update itself" do
        ability.should_not be_able_to(:manage, user)
      end
    end

  end

  context "subscriber" do


    before(:all) do
      Timecop.freeze(2012,1,1,0,0,0)
    end

    after(:all) do
      Timecop.return() 
    end
  
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }

    it "has a valid subscription" do
      user.subscriber?.should be_true
    end

    it "receives a partial refund" do
      #set a predicatable duration
      subscription.duration = 3
      #price is 1 cent per day 
      subscription.price_paid = 91 
      Timecop.freeze(2012,1,22,0,0,0) do
        subscription.expire_subscription
        subscription.refund.should == 91-21
      end
    end

    it "receives a full refund if the subscription hasn't started yet" do
      subscription.price_paid = 91
      Timecop.freeze(2011,1,1,0,0,0) do
        subscription.expire_subscription
        subscription.refund.should == 91
      end
    end
  end

end

