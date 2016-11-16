require 'trailblazer/operation'
require 'trailblazer/operation/model'
require 'active_model'
require 'reform/form/validate'
require 'reform/form/active_model/validations'
require 'securerandom'
require 'pony'

module Tyrant
  class ResetPassword < Trailblazer::Operation

    def model!(params)
      params[:model]
    end

    def process(params)
      new_authentication
      model.save
    end

  private
    def new_authentication
      auth = Tyrant::Authenticatable.new(model)
      new_password = generate_password
      auth.digest!(new_password)
      auth.sync
      notify(model.email, new_password)
    end

    def generate_password
      return SecureRandom.base64[0,8]
    end

    def notify(email, new_password)
      send_email = Tyrant::Mailer.new()
      send_email.pony_options
      send_email.notify_user(email, new_password)
    end

  end

  class Mailer 
    def pony_options
      Pony.options = {
                      from: "admin@email.com",
                      via: :smtp, 
                      via_options: {
                                    address: "smtp.gmail.com", 
                                    port: "587",
                                    domain: 'localhost:3000', 
                                    enable_starttls_auto: true, 
                                    user_name: "your_email@gmail.com", 
                                    password: "your_password", 
                                    subject: "Reset password for your application",
                                    authentication: :plain
                                    } 
                      }
    end
    
    def notify_user(email, new_password)
      Pony.mail({ to: email,
                  body: "Hi there, here your temporary password: #{new_password}. We suggest you to modify this password ASAP. Cheers",
                })
    end
  end
end