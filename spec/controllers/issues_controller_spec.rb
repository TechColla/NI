require 'rails_helper'

describe IssuesController, :type => :controller do

  setup do
    Issue.__elasticsearch__.index_name = 'ni-test'
    Issue.__elasticsearch__.create_index!
    # Issue.__elasticsearch__.import
    # Issue.__elasticsearch__.refresh_index!
  end

  context "as a guest" do
   
    context "with an issue" do
      let(:issue) { FactoryGirl.create(:published_issue) }

      describe "GET issue list" do

        it "should show issue" do
          get :index, :issue_id => issue.id
          Issue.__elasticsearch__.import
          Issue.__elasticsearch__.refresh_index!
          expect(response.status).to eq(200)
          expect(assigns(:issues).records).to include(issue)
        end

        it "should show issue JSON" do
          get :index, format: 'json', :issue_id => issue.id
          expect(response.status).to eq(200)
          Issue.__elasticsearch__.import
          Issue.__elasticsearch__.refresh_index!
          expect(JSON.parse(response.body).first['title']).to eq(issue.title)
        end

      end

      describe "GET email" do

        it "works" do
          get :email, :issue_id => issue.id
          expect(response.status).to eq(200)
        end

      end

      describe "POST push notification" do

        it "should not be able to send a push notification" do
          post :send_push_notification, :issue_id => issue.id
          expect(response).to redirect_to issues_url
        end

      end
    end
  end

  context "as a user with an issue" do

    let(:user) { FactoryGirl.create(:user) }
    let(:issue) { FactoryGirl.create(:issue) }

    before(:each) do
      sign_in user
    end

    describe "POST push notification" do

      it "should not be able to send a push notification" do
        post :send_push_notification, :issue_id => issue.id
        expect(response).to redirect_to issues_url
      end

    end

  end

  context "as a user with a purchase" do

    let(:purchase) { FactoryGirl.create(:purchase) }
    let(:user) { purchase.user }
    let(:issue) { purchase.issue }

    before(:each) do
      sign_in user
    end

    describe "POST iOS download issue for offline reading" do

      it "should be able to download issue" do
        post :show, :id => issue.id, :format => :json
        # TODO: FIX sort out why it's returning 302 redirected.
        # byebug
        expect(response.status).to eq(200)
      end

    end

  end

  context "as a subscriber with an issue" do

    before(:all) do
      Timecop.freeze(2012,1,1,0,0,0)
    end

    after(:all) do
      Timecop.return() 
    end
    
    let(:user) { FactoryGirl.create(:user) }
    let(:subscription) { FactoryGirl.create(:subscription) }
    let(:user) { subscription.user }
    let(:issue) { FactoryGirl.create(:issue) }

    it "has a valid subscription" do
      expect(user.subscriber?).to be_truthy
    end

    describe "POST push notification" do

      it "should not be able to send a push notification" do
        post :send_push_notification, :issue_id => issue.id
        expect(response).to redirect_to issues_url
      end

    end
    
  end

  context "as an admin" do

    before(:each) do
      app = Rpush::Apns::App.new
      app.name = ENV["RPUSH_APPLE_DEVELOPMENT_APP_NAME"]
      app.certificate = ENV["APPLE_DEVELOPMENT_PEM"]
      app.environment = "sandbox" # APNs environment.
      app.connections = 1
      app.save!
      sign_in user
    end

    let(:user) { FactoryGirl.create(:admin_user) }
    let(:issue) { FactoryGirl.create(:issue) }
    let(:push_registration) { FactoryGirl.create(:push_registration) }

    it "should be able to send a push notification" do
      scheduled_test_time = DateTime.now
      input_params = {
        "scheduled_datetime(1i)" => scheduled_test_time.year,
        "scheduled_datetime(2i)" => scheduled_test_time.month,
        "scheduled_datetime(3i)" => scheduled_test_time.day,
        "scheduled_datetime(4i)" => scheduled_test_time.hour,
        "scheduled_datetime(5i)" => scheduled_test_time.minute,
        "device_id" => push_registration.token,
        "alert_text" => "Test message."
      }
      
      post :send_push_notification, :issue_id => issue.id, "/issues/#{issue.id}/send_push_notification" => input_params
      expect(response).to redirect_to admin_push_notifications_path
    end

  end

end

