class Admin::BaseController < ApplicationController

	# Cancan won't work here, so we use verify_admin
	before_filter :verify_admin

	def index
		value = Settings.find_by_var('users_csv')
		if value
			@latest_csv_date = value.updated_at.strftime("digisub-%Y-%m-%d-%H:%M:%S")
		else
			@latest_csv_date = nil
		end
	end

	def reset_password_instructions_email
		@token = "fake_token"
    @resource = current_user
    @template = 'devise/mailer/reset_password_instructions'
    
    respond_to do |format|
      format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
    end
	end

	def welcome_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@user = current_user

		if params[:user_type] == "institution"
			@template = "user_mailer/make_institutional_confirmation"
		else
			@template = "user_mailer/user_signup_confirmation"
		end

		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
		end
	end

	def subscription_email
		@greeting = 'Hi'
		@issue = Issue.latest
		@issues = Issue.where(published: true).last(8).reverse
		@subscription = Subscription.first
		@user = @subscription.user

		if params[:subscription_type] == "free"
			@template = "user_mailer/free_subscription_confirmation"
		elsif params[:subscription_type] == "media"
			@template = "user_mailer/media_subscription_confirmation"
		elsif params[:subscription_type] == "cancelled"
			@template = "user_mailer/subscription_cancellation"
		elsif params[:subscription_type] == "cancelled_paypal"
			@template = "user_mailer/subscription_cancelled_via_paypal"
		else
			@template = "user_mailer/subscription_confirmation"
		end

		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
		end
	end

	def magazine_purchase_email
		@greeting = 'Hi'
		@issues = Issue.where(published: true).last(8).reverse
		@purchase = Purchase.first
		@issue = @purchase.issue
		@user = @purchase.user
		@template = "user_mailer/issue_purchase"

		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
			format.text {
				render @template, :layout => false
			}
		end
	end

	def admin_email
		@user = current_user
		@greeting = "Hello"
		@subject = "Example subject."
		@body_text = "Example body with <b>HTML</b> text and <a href='#'>links</a>."
		@template = "user_mailer/admin_email"
		
		respond_to do |format|
			format.mjml {
				render @template, :layout => false
			}
		end
	end

	def delete_cache
		if params[:cache] == "all"
			# Delete all cache
			Rails.cache.dalli.flush_all
			logger.info "CACHE: flush_all finished."
		elsif params[:cache] == "blog"
			# Flush timely posts on home page. home_blog_latest and home_web_exclusives
			categories_to_flush = ["/blog/", "/features/web-exclusive/"]
			categories_to_flush.each do |n|
				Category.where(name: n).each do |c|
					c.flush_cache
				end
			end
			Rails.cache.delete("home_blog_latest")
			Rails.cache.delete("home_web_exclusives")
			logger.info "CACHE: flush blog finished."
		end
		redirect_to admin_root_path, notice: "Cache cleared: #{params[:cache] || "None"}."
	end

	private

	def verify_admin
		redirect_to root_url unless (current_user and current_user.admin?)
	end
	
end
